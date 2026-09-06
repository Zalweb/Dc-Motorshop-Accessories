import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/web/web_session.dart';
import '../models/sale_web.dart';

/// Web-safe, Supabase-backed sale repository (cloud-only).
class SaleRepositoryWeb {
  SaleRepositoryWeb({required this.db});

  final SupabaseClient db;

  String get _bizId => WebSession.businessId ?? '';

  Future<String> _ensureBizId() async {
    if (_bizId.isNotEmpty) return _bizId;
    final id = await WebSession.ensureBusinessId(db);
    return id ?? '';
  }

  static const _tbl = 'sales';

  static List<Sale>? _cachedSales;
  static final List<StreamController<List<Sale>>> _controllers = [];
  static Timer? _pollTimer;
  static bool _isFetching = false;

  static void clearCache() {
    _cachedSales = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _isFetching = false;
  }

  static void _notifyControllers() {
    if (_cachedSales == null) return;
    final snapshot = List<Sale>.unmodifiable(_cachedSales!);
    for (final c in List.of(_controllers)) {
      if (!c.isClosed) c.add(snapshot);
    }
  }

  static bool _salesEqual(List<Sale>? a, List<Sale> b) {
    if (a == null) return false;
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final sA = a[i];
      final sB = b[i];
      if (sA.uid != sB.uid ||
          sA.status != sB.status ||
          sA.total != sB.total ||
          sA.items.length != sB.items.length ||
          sA.updatedAt != sB.updatedAt) {
        return false;
      }
    }
    return true;
  }

  Stream<List<Sale>> watchAll() {
    final controller = StreamController<List<Sale>>.broadcast();
    _controllers.add(controller);

    if (_cachedSales != null) {
      controller.add(List<Sale>.unmodifiable(_cachedSales!));
    }

    Future<void> syncFromCloud() async {
      if (_isFetching) return;
      _isFetching = true;
      try {
        final rows = await all();
        if (!_salesEqual(_cachedSales, rows)) {
          _cachedSales = rows;
          _notifyControllers();
        }
      } catch (_) {
        // Keep existing cache on transient failure
      } finally {
        _isFetching = false;
      }
    }

    syncFromCloud();
    _pollTimer ??= Timer.periodic(const Duration(seconds: 30), (_) => syncFromCloud());

    controller.onCancel = () {
      _controllers.remove(controller);
      controller.close();
      if (_controllers.isEmpty) {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    };
    return controller.stream;
  }

  Future<List<Sale>> all() async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    if (_cachedSales != null) {
      return List<Sale>.unmodifiable(_cachedSales!);
    }
    final res = await db
        .from(_tbl)
        .select('*, sale_items(*)')
        .eq('business_id', bizId)
        .order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res as List);
    final parsed = rows.map(Sale.fromJson).toList();
    _cachedSales = parsed;
    return parsed;
  }

  Future<List<Sale>> between(DateTime start, DateTime end) async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    final res = await db
        .from(_tbl)
        .select('*, sale_items(*)')
        .eq('business_id', bizId)
        .gte('created_at', start.toUtc().toIso8601String())
        .lte('created_at', end.toUtc().toIso8601String())
        .order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res as List);
    return rows.map(Sale.fromJson).toList();
  }

  Future<void> save(Sale sale) async {
    final bizId = await _ensureBizId();
    sale
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    final row = sale.toJson()
      ..['business_id'] = bizId
      ..['created_at'] = sale.createdAt.toUtc().toIso8601String();
    row.remove('items');

    // Optimistically update local cache and notify listeners immediately
    if (_cachedSales != null) {
      final list = List<Sale>.from(_cachedSales!);
      final idx = list.indexWhere((s) => s.uid == sale.uid || (s.id != 0 && s.id == sale.id));
      if (idx != -1) {
        list[idx] = sale;
      } else {
        list.insert(0, sale);
      }
      _cachedSales = list;
      _notifyControllers();
    }

    await db.from(_tbl).upsert(row, onConflict: 'id');

    // Upsert sale items matching Supabase public.sale_items table schema.
    if (sale.items.isNotEmpty) {
      final items = sale.items.map((i) {
        return <String, dynamic>{
          'sale_id': sale.uid,
          'business_id': bizId,
          if (i.productUid != null) 'product_id': i.productUid,
          if (i.variantUid != null || i.productUid != null)
            'product_variant_id': i.variantUid ?? i.productUid,
          if (i.sku != null) 'sku': i.sku,
          if (i.variantName != null) 'variant_name': i.variantName,
          'name': i.name,
          'quantity': i.quantity,
          'unit_price': i.unitPrice,
          'unit_cost': i.unitCost,
          'line_total': i.lineTotal,
        };
      }).toList();
      await db.from('sale_items').upsert(items, onConflict: 'id');
    }
  }

  /// Generates the next human-friendly sale number, e.g. "S-0001".
  Future<String> nextSaleNumber() async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return 'S-0001';
    final count = await db
        .from(_tbl)
        .select('id')
        .eq('business_id', bizId)
        .count();
    final n = count.count;
    return 'S-${(n + 1).toString().padLeft(4, '0')}';
  }
}
