import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/web/web_session.dart';
import '../models/expense_web.dart';

/// Web-safe, Supabase-backed expense repository (cloud-only).
class ExpenseRepositoryWeb {
  ExpenseRepositoryWeb({required this.db});

  final SupabaseClient db;

  String get _bizId => WebSession.businessId ?? '';

  Future<String> _ensureBizId() async {
    if (_bizId.isNotEmpty) return _bizId;
    final id = await WebSession.ensureBusinessId(db);
    return id ?? '';
  }

  static const _tbl = 'expenses';

  Stream<List<Expense>> watchAll() {
    final controller = StreamController<List<Expense>>.broadcast();
    Future<void> emit() async {
      final rows = await _fetch();
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

  Future<List<Expense>> _fetch() async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    final res = await db
        .from(_tbl)
        .select()
        .eq('business_id', bizId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res as List);
    return rows.map(Expense.fromJson).toList();
  }

  Future<List<Expense>> between(DateTime start, DateTime end) async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    final res = await db
        .from(_tbl)
        .select()
        .eq('business_id', bizId)
        .isFilter('deleted_at', null)
        .gte('created_at', start.toUtc().toIso8601String())
        .lte('created_at', end.toUtc().toIso8601String());
    final rows = List<Map<String, dynamic>>.from(res as List);
    return rows.map(Expense.fromJson).toList();
  }

  Future<void> save(Expense expense) async {
    final bizId = await _ensureBizId();
    expense
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    final row = expense.toJson()
      ..['business_id'] = bizId
      ..['created_at'] = expense.createdAt.toUtc().toIso8601String();
    await db.from(_tbl).upsert(row, onConflict: 'id');
  }

  Future<void> delete(String id) async {
    await db
        .from(_tbl)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }
}
