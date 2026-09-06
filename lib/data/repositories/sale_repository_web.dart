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

  Stream<List<Sale>> watchAll() {
    final controller = StreamController<List<Sale>>.broadcast();
    Future<void> emit() async {
      final rows = await all();
      if (!controller.isClosed) controller.add(rows);
    }

    emit();
    final timer = Timer.periodic(const Duration(seconds: 20), (_) => emit());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  Future<List<Sale>> all() async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    final res = await db
        .from(_tbl)
        .select('*, sale_items(*)')
        .eq('business_id', bizId)
        .order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res as List);
    return rows.map(Sale.fromJson).toList();
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
    final now = DateTime.now().toUtc().toIso8601String();
    final row = sale.toJson()
      ..['business_id'] = bizId
      ..['created_at'] = sale.createdAt.toUtc().toIso8601String();
    await db.from(_tbl).upsert(row, onConflict: 'id');

    // Insert sale items (replace-all for the sale).
    final items = sale.items.map((i) => i.toJson()).toList();
    // SaleItem rows use product_id from the item; pair with sale id.
    for (final item in items) {
      item['sale_id'] = sale.uid;
      item['business_id'] = bizId;
      item['updated_at'] = now;
    }
    if (items.isNotEmpty) {
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
