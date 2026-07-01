import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../api/api_exception.dart';
import '../api/backup_api.dart';
import '../api/product_image_api.dart';
import '../api/sales_api.dart';
import '../api/secure_token_store.dart';
import '../api/sync_api.dart';

/// Bidirectional delta sync (Phase 2).
///
/// Push: dirty local rows go up — catalog/config via the generic `/sync/{table}` (LWW by
/// `updatedAt`), sales via the idempotent `POST /sales` (server recomputes money).
/// Pull: rows changed since the last sync are reconciled into Isar by `uid`, and tombstones
/// delete local rows. A locally-dirty row is never clobbered by a pull until it's pushed.
class SyncService {
  SyncService({
    required Isar isar,
    required SyncApi syncApi,
    required SalesApi salesApi,
    required BackupApi backupApi,
    required ProductImageApi imageApi,
    required SecureTokenStore tokens,
    required SharedPreferences prefs,
  })  : _isar = isar,
        _syncApi = syncApi,
        _salesApi = salesApi,
        _backupApi = backupApi,
        _imageApi = imageApi,
        _tokens = tokens,
        _prefs = prefs;

  final Isar _isar;
  final SyncApi _syncApi;
  final SalesApi _salesApi;
  final BackupApi _backupApi;
  final ProductImageApi _imageApi;
  final SecureTokenStore _tokens;
  final SharedPreferences _prefs;

  /// Runs a full push-then-pull cycle. No-op (returns false) when signed out.
  Future<bool> syncNow() async {
    if (!await _tokens.hasSession()) return false;
    await _push();
    await _pull();
    return true;
  }

  /// Restores the shop's data from the cloud snapshot (`GET /backup/export`) into Isar —
  /// used on reinstall / a new device. No-op (returns false) when signed out.
  Future<bool> restoreFromCloud() async {
    if (!await _tokens.hasSession()) return false;
    final snapshot = await _backupApi.export();
    final tables = (snapshot['tables'] as Map).cast<String, dynamic>();
    await _isar.writeTxn(() async {
      for (final row in (tables['categories'] as List? ?? const [])) {
        await _applyCategory((row as Map).cast<String, dynamic>());
      }
      for (final row in (tables['products'] as List? ?? const [])) {
        await _applyProduct((row as Map).cast<String, dynamic>());
      }
      for (final row in (tables['expenses'] as List? ?? const [])) {
        await _applyExpense((row as Map).cast<String, dynamic>());
      }
    });
    return true;
  }

  // --- push -----------------------------------------------------------------

  Future<void> _push() async {
    await _pushCategories();
    await _pushExpenses();
    await _pushProducts();
    await _pushSales();
  }

  Future<void> _pushCategories() async {
    final dirty = await _isar.categorys.filter().isDirtyEqualTo(true).findAll();
    if (dirty.isEmpty) return;
    await _syncApi.push('categories', dirty.map(_categoryToJson).toList());
    await _markClean(dirty, (c) => c.isDirty = false, _isar.categorys);
  }

  Future<void> _pushExpenses() async {
    final dirty = await _isar.expenses.filter().isDirtyEqualTo(true).findAll();
    if (dirty.isEmpty) return;
    await _syncApi.push('expenses', dirty.map(_expenseToJson).toList());
    await _markClean(dirty, (e) => e.isDirty = false, _isar.expenses);
  }

  Future<void> _pushProducts() async {
    final dirty = await _isar.products.filter().isDirtyEqualTo(true).findAll();
    if (dirty.isEmpty) return;
    await _syncApi.push('products', dirty.map(_productToJson).toList());
    await _markClean(dirty, (p) => p.isDirty = false, _isar.products);
    await _uploadPendingImages(dirty);
  }

  /// Uploads images for products that have a local picture but no server URL yet.
  /// Runs after the product is pushed (the upload target must exist server-side).
  Future<void> _uploadPendingImages(List<Product> products) async {
    for (final product in products) {
      if (product.imagePath == null || product.imageUrl != null) continue;
      try {
        final url = await _imageApi.upload(product.uid, product.imagePath!);
        product.imageUrl = url;
        await _isar.writeTxn(() => _isar.products.put(product));
      } on ApiException {
        // Best-effort; the image retries on the next sync.
      }
    }
  }

  Future<void> _pushSales() async {
    final dirty = await _isar.sales.filter().isDirtyEqualTo(true).findAll();
    for (final sale in dirty) {
      await _salesApi.checkout(_saleToCheckoutJson(sale));
      sale.isDirty = false;
      await _isar.writeTxn(() => _isar.sales.put(sale));
    }
  }

  // --- pull -----------------------------------------------------------------

  Future<void> _pull() async {
    await _pullTable('categories', _applyCategory);
    await _pullTable('expenses', _applyExpense);
    await _pullTable('products', _applyProduct);
  }

  Future<void> _pullTable(
    String table,
    Future<void> Function(Map<String, dynamic>) apply,
  ) async {
    final result = await _syncApi.pull(table, since: _lastPull(table));
    await _isar.writeTxn(() async {
      for (final row in result.changes) {
        await apply(row);
      }
      for (final uid in result.tombstones) {
        await _deleteByUid(table, uid);
      }
    });
    await _prefs.setString('sync_since_$table', result.serverTime.toIso8601String());
  }

  DateTime? _lastPull(String table) {
    final raw = _prefs.getString('sync_since_$table');
    return raw == null ? null : DateTime.parse(raw);
  }

  Future<void> _applyCategory(Map<String, dynamic> row) async {
    final existing = await _isar.categorys.filter().uidEqualTo(row['id'] as String).findFirst();
    if (existing != null && existing.isDirty) return; // local edit pending push
    final category = existing ?? Category()
      ..uid = row['id'] as String
      ..name = row['name'] as String
      ..isService = (row['is_service'] ?? false) as bool
      ..updatedAt = DateTime.parse(row['updated_at'] as String)
      ..isDirty = false;
    await _isar.categorys.put(category);
  }

  Future<void> _applyExpense(Map<String, dynamic> row) async {
    final existing = await _isar.expenses.filter().uidEqualTo(row['id'] as String).findFirst();
    if (existing != null && existing.isDirty) return;
    final expense = existing ?? Expense()
      ..uid = row['id'] as String
      ..label = row['label'] as String
      ..amount = double.parse(row['amount'].toString())
      ..note = row['note'] as String?
      ..type = (row['type'] ?? 'variable') as String
      ..category = row['category'] as String?
      ..frequency = row['frequency'] as String?
      ..endDate = row['end_date'] != null ? DateTime.parse(row['end_date'] as String) : null
      ..includeInCalculations = (row['include_in_calculations'] ?? true) as bool
      ..updatedAt = DateTime.parse(row['updated_at'] as String)
      ..isDirty = false;
    await _isar.expenses.put(expense);
  }

  Future<void> _applyProduct(Map<String, dynamic> row) async {
    final existing = await _isar.products.filter().uidEqualTo(row['id'] as String).findFirst();
    if (existing != null && existing.isDirty) return;
    final product = existing ?? Product()
      ..uid = row['id'] as String
      ..name = row['name'] as String
      ..barcode = row['barcode'] as String?
      ..partNumber = row['part_number'] as String?
      ..description = row['description'] as String?
      ..unit = (row['unit'] ?? 'piece') as String
      ..isService = (row['is_service'] ?? false) as bool
      ..costPrice = double.parse(row['cost_price'].toString())
      ..sellingPrice = double.parse(row['selling_price'].toString())
      ..stockQty = (row['stock_on_hand'] ?? 0) as int
      ..imageUrl = row['image_url'] as String?
      ..updatedAt = DateTime.parse(row['updated_at'] as String)
      ..isDirty = false;
    await _isar.products.put(product);
  }

  Future<void> _deleteByUid(String table, String uid) async {
    switch (table) {
      case 'categories':
        final row = await _isar.categorys.filter().uidEqualTo(uid).findFirst();
        if (row != null) await _isar.categorys.delete(row.id);
      case 'products':
        final row = await _isar.products.filter().uidEqualTo(uid).findFirst();
        if (row != null) await _isar.products.delete(row.id);
      case 'expenses':
        final row = await _isar.expenses.filter().uidEqualTo(uid).findFirst();
        if (row != null) await _isar.expenses.delete(row.id);
    }
  }

  // --- serialization --------------------------------------------------------

  Map<String, dynamic> _categoryToJson(Category c) => {
        'id': c.uid,
        'name': c.name,
        'is_service': c.isService,
        'created_at': c.createdAt.toUtc().toIso8601String(),
        'updated_at': c.updatedAt.toUtc().toIso8601String(),
      };

  Map<String, dynamic> _expenseToJson(Expense e) => {
        'id': e.uid,
        'label': e.label,
        'amount': e.amount.toStringAsFixed(2),
        'type': e.type,
        'spent_on': _dateOnly(e.createdAt),
        'note': e.note,
        'category': e.category,
        'frequency': e.frequency,
        'end_date': e.endDate?.toUtc().toIso8601String(),
        'include_in_calculations': e.includeInCalculations,
        'created_at': e.createdAt.toUtc().toIso8601String(),
        'updated_at': e.updatedAt.toUtc().toIso8601String(),
      };

  Map<String, dynamic> _productToJson(Product p) => {
        'id': p.uid,
        'name': p.name,
        'barcode': p.barcode,
        'part_number': p.partNumber,
        'description': p.description,
        'unit': p.unit,
        'is_service': p.isService,
        'cost_price': p.costPrice.toStringAsFixed(2),
        'selling_price': p.sellingPrice.toStringAsFixed(2),
        'reorder_point': 0,
        'created_at': p.createdAt.toUtc().toIso8601String(),
        'updated_at': p.updatedAt.toUtc().toIso8601String(),
      };

  Map<String, dynamic> _saleToCheckoutJson(Sale s) => {
        'id': s.uid,
        'customer_name': s.customerName,
        'discount_total': s.discount.toStringAsFixed(2),
        'items': [
          for (final item in s.items)
            {
              'product_id': ?item.productUid,
              'name': item.name,
              'unit_price': item.unitPrice.toStringAsFixed(2),
              'quantity': item.quantity,
            },
        ],
      };

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _markClean<T>(
    List<T> rows,
    void Function(T) clear,
    IsarCollection<T> collection,
  ) async {
    for (final row in rows) {
      clear(row);
    }
    await _isar.writeTxn(() => collection.putAll(rows));
  }
}
