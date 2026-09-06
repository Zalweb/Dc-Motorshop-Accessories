import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/security_sanitizer.dart';
import '../../core/web/web_session.dart';
import '../models/inventory_transaction_web.dart';

/// Web-safe, Supabase-backed inventory-transaction repository (cloud-only).
class InventoryRepositoryWeb {
  InventoryRepositoryWeb({required this.db});

  final SupabaseClient db;

  String get _bizId => WebSession.businessId ?? '';

  Future<String> _ensureBizId() async {
    if (_bizId.isNotEmpty) return _bizId;
    final id = await WebSession.ensureBusinessId(db);
    return id ?? '';
  }

  static const _tbl = 'inventory_transactions';

  static List<InventoryTransaction>? _cachedTx;
  static final List<StreamController<List<InventoryTransaction>>> _controllers = [];
  static Timer? _pollTimer;
  static bool _isFetching = false;

  static void clearCache() {
    _cachedTx = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _isFetching = false;
  }

  static void _notifyControllers() {
    if (_cachedTx == null) return;
    for (final c in List.of(_controllers)) {
      if (!c.isClosed) c.add(List<InventoryTransaction>.unmodifiable(_cachedTx!.take(50)));
    }
  }

  static bool _txEqual(List<InventoryTransaction>? a, List<InventoryTransaction> b) {
    if (a == null) return false;
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final tA = a[i];
      final tB = b[i];
      if (tA.uid != tB.uid ||
          tA.quantity != tB.quantity ||
          tA.transactionType != tB.transactionType ||
          tA.updatedAt != tB.updatedAt) {
        return false;
      }
    }
    return true;
  }

  Stream<List<InventoryTransaction>> watchRecent({int limit = 50}) {
    final controller = StreamController<List<InventoryTransaction>>.broadcast();
    _controllers.add(controller);

    if (_cachedTx != null) {
      controller.add(List<InventoryTransaction>.unmodifiable(_cachedTx!.take(limit)));
    }

    Future<void> syncFromCloud() async {
      if (_isFetching) return;
      _isFetching = true;
      try {
        final rows = await all();
        if (!_txEqual(_cachedTx, rows)) {
          _cachedTx = rows;
          _notifyControllers();
        }
      } catch (_) {
        // Retain cache
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

  Future<List<InventoryTransaction>> all() async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    if (_cachedTx != null) {
      return _cachedTx!;
    }
    final res = await db
        .from(_tbl)
        .select()
        .eq('business_id', bizId)
        .order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res as List);
    final parsed = rows.map(InventoryTransaction.fromJson).toList();
    _cachedTx = parsed;
    return parsed;
  }

  Future<List<InventoryTransaction>> byVariantUid(String variantUid) async {
    final clean = sanitizePostgrestFilter(variantUid);
    if (clean.isEmpty) return [];
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    final res = await db
        .from(_tbl)
        .select()
        .eq('business_id', bizId)
        .or('product_variant_uid.eq.$clean,product_variant_id.eq.$clean')
        .order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res as List);
    return rows.map(InventoryTransaction.fromJson).toList();
  }

  Future<void> record(InventoryTransaction tx) async {
    final bizId = await _ensureBizId();
    tx
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    final row = <String, dynamic>{
      'id': tx.uid,
      'business_id': bizId,
      'product_variant_id': tx.productVariantUid,
      'transaction_type': tx.transactionType,
      'quantity': tx.quantity,
      if (tx.unitCost != null) 'unit_cost': tx.unitCost,
      if (tx.referenceType != null) 'reference_type': tx.referenceType,
      if (tx.referenceId != null) 'reference_id': tx.referenceId,
      if (tx.notes != null) 'notes': tx.notes,
      'created_at': tx.createdAt.toUtc().toIso8601String(),
    };

    if (_cachedTx != null) {
      final list = List<InventoryTransaction>.from(_cachedTx!)..insert(0, tx);
      _cachedTx = list;
      _notifyControllers();
    }

    await db.from(_tbl).insert(row);
  }

  Future<void> recordBatch(List<InventoryTransaction> transactions) async {
    final bizId = await _ensureBizId();
    final rows = transactions.map((tx) {
      tx
        ..updatedAt = DateTime.now()
        ..isDirty = true;
      return <String, dynamic>{
        'id': tx.uid,
        'business_id': bizId,
        'product_variant_id': tx.productVariantUid,
        'transaction_type': tx.transactionType,
        'quantity': tx.quantity,
        if (tx.unitCost != null) 'unit_cost': tx.unitCost,
        if (tx.referenceType != null) 'reference_type': tx.referenceType,
        if (tx.referenceId != null) 'reference_id': tx.referenceId,
        if (tx.notes != null) 'notes': tx.notes,
        'created_at': tx.createdAt.toUtc().toIso8601String(),
      };
    }).toList();

    if (_cachedTx != null) {
      final list = List<InventoryTransaction>.from(_cachedTx!)..insertAll(0, transactions);
      _cachedTx = list;
      _notifyControllers();
    }

    if (rows.isNotEmpty) await db.from(_tbl).insert(rows);
  }
}
