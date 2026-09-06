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

  Stream<List<InventoryTransaction>> watchRecent({int limit = 50}) {
    final controller = StreamController<List<InventoryTransaction>>.broadcast();
    Future<void> emit() async {
      final rows = await all();
      if (!controller.isClosed) controller.add(rows.take(limit).toList());
    }

    emit();
    final timer = Timer.periodic(const Duration(seconds: 20), (_) => emit());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  Future<List<InventoryTransaction>> all() async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    final res = await db
        .from(_tbl)
        .select()
        .eq('business_id', bizId)
        .order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res as List);
    return rows.map(InventoryTransaction.fromJson).toList();
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
    final row = tx.toJson()
      ..['business_id'] = bizId
      ..['created_at'] = tx.createdAt.toUtc().toIso8601String();
    await db.from(_tbl).insert(row);
  }

  Future<void> recordBatch(List<InventoryTransaction> transactions) async {
    final bizId = await _ensureBizId();
    final rows = transactions.map((tx) {
      tx
        ..updatedAt = DateTime.now()
        ..isDirty = true;
      return tx.toJson()
        ..['business_id'] = bizId
        ..['created_at'] = tx.createdAt.toUtc().toIso8601String();
    }).toList();
    if (rows.isNotEmpty) await db.from(_tbl).insert(rows);
  }
}
