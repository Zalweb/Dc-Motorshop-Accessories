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

  static List<Expense>? _cachedExpenses;
  static final List<StreamController<List<Expense>>> _controllers = [];
  static Timer? _pollTimer;
  static bool _isFetching = false;

  static void clearCache() {
    _cachedExpenses = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _isFetching = false;
  }

  static void _notifyControllers() {
    if (_cachedExpenses == null) return;
    final snapshot = List<Expense>.unmodifiable(_cachedExpenses!);
    for (final c in List.of(_controllers)) {
      if (!c.isClosed) c.add(snapshot);
    }
  }

  static bool _expensesEqual(List<Expense>? a, List<Expense> b) {
    if (a == null) return false;
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final eA = a[i];
      final eB = b[i];
      if (eA.uid != eB.uid ||
          eA.amount != eB.amount ||
          eA.category != eB.category ||
          eA.note != eB.note ||
          eA.updatedAt != eB.updatedAt) {
        return false;
      }
    }
    return true;
  }

  Stream<List<Expense>> watchAll() {
    final controller = StreamController<List<Expense>>.broadcast();
    _controllers.add(controller);

    if (_cachedExpenses != null) {
      controller.add(List<Expense>.unmodifiable(_cachedExpenses!));
    }

    Future<void> syncFromCloud() async {
      if (_isFetching) return;
      _isFetching = true;
      try {
        final rows = await _fetch();
        if (!_expensesEqual(_cachedExpenses, rows)) {
          _cachedExpenses = rows;
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

  Future<List<Expense>> all() async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    if (_cachedExpenses != null) {
      return List<Expense>.unmodifiable(_cachedExpenses!);
    }
    final rows = await _fetch();
    _cachedExpenses = rows;
    return rows;
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
    final parsed = rows.map(Expense.fromJson).toList();
    _cachedExpenses = parsed;
    return parsed;
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

    if (_cachedExpenses != null) {
      final list = List<Expense>.from(_cachedExpenses!);
      final idx = list.indexWhere((e) => e.uid == expense.uid || (e.id != 0 && e.id == expense.id));
      if (idx != -1) {
        list[idx] = expense;
      } else {
        list.insert(0, expense);
      }
      _cachedExpenses = list;
      _notifyControllers();
    }

    await db.from(_tbl).upsert(row, onConflict: 'id');
  }

  Future<void> delete(String id) async {
    if (_cachedExpenses != null) {
      final list = List<Expense>.from(_cachedExpenses!)
        ..removeWhere((e) => e.uid == id || e.id.toString() == id);
      _cachedExpenses = list;
      _notifyControllers();
    }
    await db
        .from(_tbl)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }
}
