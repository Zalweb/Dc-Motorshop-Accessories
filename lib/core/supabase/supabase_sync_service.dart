import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/business_settings.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../data/models/user.dart';
import '../sync/sync_state_provider.dart';
import 'supabase_service.dart';
import 'supabase_storage_service.dart';

/// Offline-first bidirectional sync between Isar (local) and Supabase (cloud).
///
/// Strategy:
///  - **Push**: Dirty local rows are upserted to Supabase. Sales are
///    append-only (never updated server-side). Deletes are soft (deleted_at).
///  - **Pull**: Rows changed since the last successful sync are fetched and
///    applied to Isar, skipping any row that is still locally dirty.
///    Tombstones (deleted_at != null) trigger local deletion.
///
/// The sync is triggered:
///  - Automatically on reconnect (via [ConnectivitySync]).
///  - Manually from the More / Cloud Backup screen.
///  - Once after login to restore data on a new device.
class SupabaseSyncService {
  SupabaseSyncService({
    required Isar isar,
    required SharedPreferences prefs,
    required SupabaseStorageService storage,
    required SyncStateNotifier syncState,
  })  : _isar = isar,
        _prefs = prefs,
        _storage = storage,
        _syncState = syncState;

  final Isar _isar;
  final SharedPreferences _prefs;
  final SupabaseStorageService _storage;
  final SyncStateNotifier _syncState;

  get _db => SupabaseService.client;

  static const _syncSincePrefix = 'supabase_sync_since_';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Full push-then-pull cycle.
  ///
  /// Returns false if the user is not signed in (no-op).
  Future<bool> syncNow() async {
    if (!SupabaseService.hasSession) return false;
    final bizId = await _businessId();
    if (bizId == null) return false;
    
    _syncState.setSyncing();

    try {
      // Ensure the business profile exists in the cloud before pushing foreign-key data.
      final settings = await _isar.businessSettings.get(BusinessSettings.singletonId);
      if (settings != null) await pushBusinessSettings(settings);

      await _push(bizId);
      await _pull(bizId);
      
      _syncState.setSuccess();
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        _syncState.setConflict();
      } else {
        _syncState.setError();
      }
      rethrow;
    } catch (e) {
      _syncState.setError();
      rethrow;
    }
  }

  /// Restores all cloud data into the local Isar database.
  ///
  /// Used on first login on a new device. Equivalent to a full pull with
  /// no "since" timestamp (downloads everything).
  Future<bool> restoreFromCloud() async {
    if (!SupabaseService.hasSession) return false;
    final bizId = await _businessId();
    if (bizId == null) return false;
    
    // Push local settings up first in case it's a linked account.
    final settings = await _isar.businessSettings.get(BusinessSettings.singletonId);
    if (settings != null) await pushBusinessSettings(settings);

    // Clear local data to ensure hard-deleted cloud rows are removed locally
    await _isar.writeTxn(() async {
      await _isar.categorys.clear();
      await _isar.products.clear();
      await _isar.expenses.clear();
      await _isar.sales.clear();
    });

    // Pull categories first so products can resolve category_id → name
    await _pullTable(
      table: 'categories',
      bizId: bizId,
      since: null,
      apply: _applyCategory,
    );
    await _pullTable(
      table: 'products',
      bizId: bizId,
      since: null,
      apply: _applyProduct,
      columns: 'id,business_id,name,barcode,part_number,description,category_id,brand,unit,is_service,cost_price,selling_price,stock_on_hand,image_url,created_at,updated_at,deleted_at',
    );
    await _pullTable(
      table: 'expenses',
      bizId: bizId,
      since: null,
      apply: _applyExpense,
      columns: 'id,business_id,label,amount,note,type,category_id,frequency,end_date,include_in_calculations,spent_on,created_at,updated_at,deleted_at',
    );
    await _pullSales(bizId: bizId, since: null);
    // Pull business profile last (calendar days, checklist, logo)
    await _pullBusinessProfile(bizId);
    return true;
  }

  /// Pushes business settings (onboarding data, theme, etc.) to Supabase.
  Future<void> pushBusinessSettings(BusinessSettings settings) async {
    if (!SupabaseService.hasSession) return;
    final bizId = await _businessId();
    if (bizId == null) return;

    final user = await _isar.users.filter().uidEqualTo(SupabaseService.currentUserId!).findFirst();
    final isComplete = user?.onboardingComplete ?? true;

    final profileData = <String, dynamic>{
      'id': bizId,
      'owner_id': SupabaseService.currentUserId,
      'business_name': settings.businessName,
      'business_type': settings.businessType,
      'address': settings.address,
      'phone': settings.phone,
      'email': settings.email,
      'timezone': settings.timezone,
      'currency': settings.currency,
      'theme_color': settings.themeColor,
      'receipt_qr_link': settings.receiptQrLink,
      'onboarding_complete': isComplete,
      'new_shop_setup': user?.newShopSetup ?? true,
      'allow_sell_when_out_of_stock': settings.allowSellWhenOutOfStock,
      'track_partial_change': settings.trackPartialChange,
      'include_unpaid_in_reports': settings.includeUnpaidInReports,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (settings.logoPath != null && settings.logoPath!.isNotEmpty) {
      if (!settings.logoPath!.startsWith('http')) {
        final url = await _storage.uploadLogoImage(
          businessUid: bizId,
          localPath: settings.logoPath!,
        );
        if (url != null) {
          settings.logoPath = url;
          await _isar.writeTxn(() => _isar.businessSettings.put(settings));
          profileData['logo_url'] = url;
        }
      } else {
        profileData['logo_url'] = settings.logoPath;
      }
    }

    await _db.from('business_profiles').upsert(profileData);

    // ── Push calendar days to the normalized table ────────────────────────
    final closedDates = _prefs.getStringList('calendar_closed_dates') ?? [];
    final metaRaw = _prefs.getString('calendar_closed_meta') ?? '{}';
    Map<String, dynamic> metaMap = {};
    try { metaMap = (jsonDecode(metaRaw) as Map).cast<String, dynamic>(); } catch (_) {}

    if (closedDates.isNotEmpty) {
      final calendarRows = closedDates.map((d) => {
        'business_id': bizId,
        'day': d,
        'is_closed': true,
        'note': metaMap[d]?.toString(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).toList();
      await _db.from('business_calendar_days').upsert(
        calendarRows,
        onConflict: 'business_id,day',
      );
    }

    // ── Push onboarding checklist items to the normalized table ──────────
    if (settings.completedChecklistItems.isNotEmpty) {
      final checklistRows = settings.completedChecklistItems.map((key) => {
        'business_id': bizId,
        'item_key': key,
      }).toList();
      await _db.from('onboarding_checklist_items').upsert(
        checklistRows,
        onConflict: 'business_id,item_key',
      );
    }
  }


  // ── Push ───────────────────────────────────────────────────────────────────

  Future<void> _push(String bizId) async {
    await _pushCategories(bizId);
    await _pushExpenses(bizId);
    await _pushProducts(bizId);
    await _pushSales(bizId);
  }

  Future<void> _pushCategories(String bizId) async {
    final dirty =
        await _isar.categorys.filter().isDirtyEqualTo(true).findAll();
    if (dirty.isEmpty) return;

    await _db.from('categories').upsert(
      dirty.map((c) => _categoryToRow(c, bizId)).toList(),
    );

    await _isar.writeTxn(() async {
      for (final c in dirty) {
        c.isDirty = false;
      }
      await _isar.categorys.putAll(dirty);
    });
  }

  Future<void> _pushExpenses(String bizId) async {
    final dirty =
        await _isar.expenses.filter().isDirtyEqualTo(true).findAll();
    if (dirty.isEmpty) return;

    // Build rows asynchronously to resolve category_id FK
    final rows = await Future.wait(
      dirty.map((e) => _expenseToRowAsync(e, bizId)),
    );

    await _db.from('expenses').upsert(rows);

    await _isar.writeTxn(() async {
      for (final e in dirty) {
        e.isDirty = false;
      }
      await _isar.expenses.putAll(dirty);
    });
  }

  Future<void> _pushProducts(String bizId) async {
    final dirty =
        await _isar.products.filter().isDirtyEqualTo(true).findAll();
    if (dirty.isEmpty) return;

    // Build rows asynchronously to resolve category_id FK
    final rows = await Future.wait(
      dirty.map((p) => _productToRowAsync(p, bizId)),
    );

    await _db.from('products').upsert(rows);

    await _isar.writeTxn(() async {
      for (final p in dirty) {
        p.isDirty = false;
      }
      await _isar.products.putAll(dirty);
    });
  }

  Future<void> _pushSales(String bizId) async {
    final dirty = await _isar.sales.filter().isDirtyEqualTo(true).findAll();
    for (final sale in dirty) {
      // Upsert the sale row.
      await _db.from('sales').upsert(_saleToRow(sale, bizId));

      // Upsert sale items (delete-then-insert by sale_id for simplicity).
      await _db.from('sale_items').delete().eq('sale_id', sale.uid);
      
      final itemRows = sale.items.map((item) {
        return {
          'sale_id': sale.uid,
          'business_id': bizId,
          'product_id': item.productUid,
          'name': item.name,
          'quantity': item.quantity,
          'unit_price': item.unitPrice.toStringAsFixed(2),
          'unit_cost': item.unitCost.toStringAsFixed(2),
          'line_total': item.lineTotal.toStringAsFixed(2),
        };
      }).toList();

      if (itemRows.isNotEmpty) {
        await _db.from('sale_items').insert(itemRows);
      }

      sale.isDirty = false;
      await _isar.writeTxn(() => _isar.sales.put(sale));
    }
  }

  // ── Pull ───────────────────────────────────────────────────────────────────

  Future<void> _pull(String bizId) async {
    await _pullBusinessProfile(bizId);
    await _pullTable(
      table: 'categories',
      bizId: bizId,
      since: _lastSync('categories'),
      apply: _applyCategory,
    );
    // Use explicit columns to prevent PostgREST from auto-embedding the
    // categories FK relationship (category_id) as a nested object.
    await _pullTable(
      table: 'products',
      bizId: bizId,
      since: _lastSync('products'),
      apply: _applyProduct,
      columns: 'id,business_id,name,barcode,part_number,description,category_id,brand,unit,is_service,cost_price,selling_price,stock_on_hand,image_url,created_at,updated_at,deleted_at',
    );
    await _pullTable(
      table: 'expenses',
      bizId: bizId,
      since: _lastSync('expenses'),
      apply: _applyExpense,
      columns: 'id,business_id,label,amount,note,type,category_id,frequency,end_date,include_in_calculations,spent_on,created_at,updated_at,deleted_at',
    );
    await _pullSales(bizId: bizId, since: _lastSync('sales'));
  }

  Future<void> _pullTable({
    required String table,
    required String bizId,
    required DateTime? since,
    required Future<void> Function(Map<String, dynamic>) apply,
    String? columns,         // explicit columns to prevent FK auto-embedding
  }) async {
    var query = _db
        .from(table)
        .select(columns ?? '*')
        .eq('business_id', bizId);

    if (since != null) {
      query = query.gte('updated_at', since.toUtc().toIso8601String()) as dynamic;
    }

    final rows = await query as List<dynamic>;
    final serverTime = DateTime.now().toUtc();

    // NOTE: apply functions perform Isar reads (e.g. category lookups), so
    // they cannot run inside a shared writeTxn. Each handles its own write.
    for (final row in rows) {
      await apply((row as Map).cast<String, dynamic>());
    }

    await _prefs.setString(
      '$_syncSincePrefix$table',
      serverTime.toIso8601String(),
    );
  }

  Future<void> _pullBusinessProfile(String bizId) async {
    try {
      final profile = await _db
          .from('business_profiles')
          .select()
          .eq('id', bizId)
          .maybeSingle();

      if (profile != null) {
        if (profile['logo_url'] != null) {
          final settings = await _isar.businessSettings.where().findFirst();
          if (settings != null) {
            settings.logoPath = profile['logo_url']?.toString();
            await _isar.writeTxn(() => _isar.businessSettings.put(settings));
          }
        }
      }

      // ── Pull calendar days from the normalized table ──────────────────
      final calendarRows = await _db
          .from('business_calendar_days')
          .select()
          .eq('business_id', bizId)
          .eq('is_closed', true) as List<dynamic>;

      if (calendarRows.isNotEmpty) {
        final dates = <String>[];
        final meta = <String, String>{};
        for (final row in calendarRows) {
          final day = (row as Map)['day']?.toString() ?? '';
          if (day.isNotEmpty) dates.add(day);
          final note = row['note']?.toString();
          if (note != null && note.isNotEmpty) meta[day] = note;
        }
        await _prefs.setStringList('calendar_closed_dates', dates);
        await _prefs.setString('calendar_closed_meta', jsonEncode(meta));
      }

      // ── Pull onboarding checklist from the normalized table ─────────
      final checklistRows = await _db
          .from('onboarding_checklist_items')
          .select('item_key')
          .eq('business_id', bizId) as List<dynamic>;

      if (checklistRows.isNotEmpty) {
        final keys = checklistRows
            .map((r) => (r as Map)['item_key']?.toString() ?? '')
            .where((k) => k.isNotEmpty)
            .toList();
        final settings = await _isar.businessSettings.where().findFirst();
        if (settings != null) {
          settings.completedChecklistItems = keys;
          await _isar.writeTxn(() => _isar.businessSettings.put(settings));
        }
      }
    } catch (_) {}
  }


  Future<void> _pullSales({
    required String bizId,
    required DateTime? since,
  }) async {
    var query = _db
        .from('sales')
        .select('*, sale_items(*)')
        .eq('business_id', bizId);

    if (since != null) {
      query = query.gte('updated_at', since.toUtc().toIso8601String()) as dynamic;
    }

    final rows = await query as List<dynamic>;
    final serverTime = DateTime.now().toUtc();

    // NOTE: _applySale does Isar reads (to resolve productId), so it cannot
    // run inside a shared writeTxn. Each call handles its own write.
    for (final row in rows) {
      await _applySale((row as Map).cast<String, dynamic>());
    }

    await _prefs.setString(
      '${_syncSincePrefix}sales',
      serverTime.toIso8601String(),
    );
  }

  // ── Apply functions (pull reconciliation) ──────────────────────────────────

  Future<void> _applyCategory(Map<String, dynamic> row) async {
    final rowId = row['id']?.toString();
    if (rowId == null) return;

    // Tombstone: deleted on server → remove locally.
    if (row['deleted_at'] != null) {
      final existing = await _isar.categorys.filter().uidEqualTo(rowId).findFirst();
      if (existing != null) await _isar.writeTxn(() => _isar.categorys.delete(existing.id));
      return;
    }

    final existing = await _isar.categorys.filter().uidEqualTo(rowId).findFirst();
    if (existing != null && existing.isDirty) return;

    final category = existing ?? Category();
    category
      ..uid = rowId
      ..name = row['name']?.toString() ?? ''
      ..isService = (row['is_service'] ?? false) as bool
      ..updatedAt = DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now()
      ..isDirty = false;

    await _isar.writeTxn(() => _isar.categorys.put(category));
  }

  Future<void> _applyProduct(Map<String, dynamic> row) async {
    final rowId = row['id']?.toString();
    if (rowId == null) return;

    if (row['deleted_at'] != null) {
      final existing = await _isar.products.filter().uidEqualTo(rowId).findFirst();
      if (existing != null) await _isar.writeTxn(() => _isar.products.delete(existing.id));
      return;
    }

    final existing = await _isar.products.filter().uidEqualTo(rowId).findFirst();
    if (existing != null && existing.isDirty) return;

    // Resolve category name from category_id FK (safe: UUID is always a plain string)
    String? categoryName;
    final catId = row['category_id']?.toString();
    if (catId != null && catId.contains('-')) {  // basic UUID validation
      final cat = await _isar.categorys.filter().uidEqualTo(catId).findFirst();
      if (cat != null) categoryName = cat.name;
    }

    final product = existing ?? Product();
    product
      ..uid = rowId
      ..name = row['name']?.toString() ?? ''
      ..barcode = row['barcode']?.toString()
      ..partNumber = row['part_number']?.toString()
      ..description = row['description']?.toString()
      ..category = categoryName
      ..brand = row['brand']?.toString()
      ..unit = row['unit']?.toString() ?? 'piece'
      ..isService = (row['is_service'] ?? false) as bool
      ..costPrice = double.tryParse(row['cost_price'].toString()) ?? 0
      ..sellingPrice = double.tryParse(row['selling_price'].toString()) ?? 0
      ..stockQty = (row['stock_on_hand'] as num?)?.toInt() ?? 0
      ..imageUrl = row['image_url']?.toString()
      ..updatedAt = DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now()
      ..isDirty = false;

    await _isar.writeTxn(() => _isar.products.put(product));
  }

  Future<void> _applyExpense(Map<String, dynamic> row) async {
    final rowId = row['id']?.toString();
    if (rowId == null) return;

    if (row['deleted_at'] != null) {
      final existing = await _isar.expenses.filter().uidEqualTo(rowId).findFirst();
      if (existing != null) await _isar.writeTxn(() => _isar.expenses.delete(existing.id));
      return;
    }

    final existing = await _isar.expenses.filter().uidEqualTo(rowId).findFirst();
    if (existing != null && existing.isDirty) return;

    // Resolve category name from category_id FK
    String? categoryName;
    final catId = row['category_id']?.toString();
    if (catId != null && catId.contains('-')) {  // basic UUID validation
      final cat = await _isar.categorys.filter().uidEqualTo(catId).findFirst();
      if (cat != null) categoryName = cat.name;
    }

    final expense = existing ?? Expense();
    expense
      ..uid = rowId
      ..label = row['label']?.toString() ?? ''
      ..amount = double.tryParse(row['amount'].toString()) ?? 0
      ..note = row['note']?.toString()
      ..type = row['type']?.toString() ?? 'variable'
      ..category = categoryName
      ..frequency = row['frequency']?.toString()
      ..endDate = row['end_date'] != null
          ? DateTime.tryParse(row['end_date'].toString())?.toLocal()
          : null
      ..includeInCalculations = (row['include_in_calculations'] ?? true) as bool
      ..updatedAt = DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now()
      ..isDirty = false;

    await _isar.writeTxn(() => _isar.expenses.put(expense));
  }

  Future<void> _applySale(Map<String, dynamic> row) async {
    final rowId = row['id']?.toString();
    if (rowId == null) return;

    final existing = await _isar.sales.filter().uidEqualTo(rowId).findFirst();
    if (existing != null && existing.isDirty) return;

    // sale_items is a nested list from the join — must be cast carefully
    final rawItems = row['sale_items'];
    final itemRows = (rawItems is List ? rawItems : <dynamic>[])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    final sale = existing ?? Sale();
    sale
      ..uid = rowId
      ..saleNumber = row['sale_number']?.toString() ?? ''
      ..customerName = row['customer_name']?.toString()
      ..subtotal = double.tryParse(row['subtotal'].toString()) ?? 0
      ..discount = double.tryParse(row['discount'].toString()) ?? 0
      ..total = double.tryParse(row['total'].toString()) ?? 0
      ..status = row['status']?.toString() ?? 'paid'
      ..paymentMethod = row['payment_method']?.toString() ?? 'cash'
      ..amountReceived = double.tryParse(row['amount_received'].toString()) ?? 0
      ..notes = row['notes']?.toString()
      ..createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now()
      ..updatedAt = DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now()
      ..isDirty = false;

    // Build items — resolve local productId from productUid for category lookups
    final resolvedItems = <SaleItem>[];
    for (final item in itemRows) {
      final productUid = item['product_id']?.toString();
      int? localProductId;
      if (productUid != null && productUid.contains('-')) {
        final localProduct = await _isar.products.filter().uidEqualTo(productUid).findFirst();
        localProductId = localProduct?.id;
      }
      resolvedItems.add(SaleItem()
        ..name = item['name']?.toString() ?? ''
        ..quantity = (item['quantity'] as num?)?.toInt() ?? 1
        ..unitPrice = double.tryParse(item['unit_price'].toString()) ?? 0
        ..unitCost = double.tryParse(item['unit_cost'].toString()) ?? 0
        ..lineTotal = double.tryParse(item['line_total'].toString()) ?? 0
        ..productUid = productUid
        ..productId = localProductId);
    }
    sale.items = resolvedItems;

    await _isar.writeTxn(() => _isar.sales.put(sale));
  }

  // ── Serialization (local → Supabase row) ───────────────────────────────────

  Map<String, dynamic> _categoryToRow(Category c, String bizId) => {
        'id': c.uid,
        'business_id': bizId,
        'name': c.name,
        'is_service': c.isService,
        'created_at': c.createdAt.toUtc().toIso8601String(),
        'updated_at': c.updatedAt.toUtc().toIso8601String(),
      };

  Future<Map<String, dynamic>> _expenseToRowAsync(Expense e, String bizId) async {
    // Resolve category_id from local Isar by matching category name
    String? catId;
    if (e.category != null) {
      final cat = await _isar.categorys
          .filter()
          .nameEqualTo(e.category!, caseSensitive: false)
          .findFirst();
      catId = cat?.uid;
    }
    return {
      'id': e.uid,
      'business_id': bizId,
      'label': e.label,
      'amount': e.amount.toStringAsFixed(2),
      'note': e.note,
      'type': e.type,
      'category_id': catId,
      'frequency': e.frequency,
      'end_date': e.endDate?.toUtc().toIso8601String(),
      'include_in_calculations': e.includeInCalculations,
      'spent_on': _dateOnly(e.createdAt),
      'created_at': e.createdAt.toUtc().toIso8601String(),
      'updated_at': e.updatedAt.toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _productToRowAsync(Product p, String bizId) async {
    // Resolve category_id from local Isar by matching category name
    String? catId;
    if (p.category != null) {
      final cat = await _isar.categorys
          .filter()
          .nameEqualTo(p.category!, caseSensitive: false)
          .findFirst();
      catId = cat?.uid;
    }
    return {
      'id': p.uid,
      'business_id': bizId,
      'name': p.name,
      'barcode': p.barcode,
      'part_number': p.partNumber,
      'description': p.description,
      'category_id': catId,
      'brand': p.brand,
      'unit': p.unit,
      'is_service': p.isService,
      'cost_price': p.costPrice.toStringAsFixed(2),
      'selling_price': p.sellingPrice.toStringAsFixed(2),
      'stock_on_hand': p.stockQty,
      'image_url': p.imageUrl,
      'created_at': p.createdAt.toUtc().toIso8601String(),
      'updated_at': p.updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _saleToRow(Sale s, String bizId) => {
        'id': s.uid,
        'business_id': bizId,
        'sale_number': s.saleNumber,
        'customer_name': s.customerName,
        'subtotal': s.subtotal.toStringAsFixed(2),
        'discount': s.discount.toStringAsFixed(2),
        'total': s.total.toStringAsFixed(2),
        'status': s.status,
        'payment_method': s.paymentMethod,
        'amount_received': s.amountReceived.toStringAsFixed(2),
        'notes': s.notes,
        'created_at': s.createdAt.toUtc().toIso8601String(),
        'updated_at': s.updatedAt.toUtc().toIso8601String(),
      };

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  DateTime? _lastSync(String table) {
    final raw = _prefs.getString('$_syncSincePrefix$table');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Returns the business_profiles.id for the current user.
  /// This is distinct from auth.uid() (owner_id).
  Future<String?> _businessId() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return null;

    // Check cache first.
    final cached = _prefs.getString('supabase_business_id');
    if (cached != null) return cached;

    // Fetch from Supabase.
    final row = await _db
        .from('business_profiles')
        .select('id')
        .eq('owner_id', uid)
        .maybeSingle();

    if (row == null) {
      final settings = await _isar.businessSettings.get(BusinessSettings.singletonId);
      if (settings != null && settings.uid.isNotEmpty) {
        return settings.uid;
      }
      return null;
    }
    
    final bizId = row['id']?.toString();
    if (bizId == null) return null;
    await _prefs.setString('supabase_business_id', bizId);
    return bizId;
  }

  /// Clears the cached business_id (call on logout).
  Future<void> clearCache() async {
    await _prefs.remove('supabase_business_id');
    // Clear all sync timestamps so a fresh login re-downloads everything.
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith(_syncSincePrefix))
        .toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
