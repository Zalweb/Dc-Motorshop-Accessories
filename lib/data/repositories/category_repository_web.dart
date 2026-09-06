import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_web.dart';
import '../../core/web/web_session.dart';

/// Web-safe, Supabase-backed category repository (cloud-only).
class CategoryRepositoryWeb {
  CategoryRepositoryWeb({required this.db});

  String get _bizId => WebSession.businessId ?? '';
  final SupabaseClient db;

  Future<String> _ensureBizId() async {
    if (_bizId.isNotEmpty) return _bizId;
    final id = await WebSession.ensureBusinessId(db);
    return id ?? '';
  }

  static const _tbl = 'categories';

  static List<Category>? _cachedCategories;
  static final List<StreamController<List<Category>>> _controllers = [];
  static Timer? _pollTimer;
  static bool _isFetching = false;

  static void clearCache() {
    _cachedCategories = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _isFetching = false;
  }

  static void _notifyControllers() {
    if (_cachedCategories == null) return;
    final snapshot = List<Category>.unmodifiable(_cachedCategories!);
    for (final c in List.of(_controllers)) {
      if (!c.isClosed) c.add(snapshot);
    }
  }

  static bool _categoriesEqual(List<Category>? a, List<Category> b) {
    if (a == null) return false;
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final cA = a[i];
      final cB = b[i];
      if (cA.uid != cB.uid || cA.name != cB.name || cA.isService != cB.isService) {
        return false;
      }
    }
    return true;
  }

  Stream<List<Category>> watchAll() {
    final controller = StreamController<List<Category>>.broadcast();
    _controllers.add(controller);

    if (_cachedCategories != null) {
      controller.add(List<Category>.unmodifiable(_cachedCategories!));
    }

    Future<void> syncFromCloud() async {
      if (_isFetching) return;
      _isFetching = true;
      try {
        final rows = await _fetch();
        if (!_categoriesEqual(_cachedCategories, rows)) {
          _cachedCategories = rows;
          _notifyControllers();
        }
      } catch (_) {
        // Retain cache
      } finally {
        _isFetching = false;
      }
    }

    syncFromCloud();
    _pollTimer ??= Timer.periodic(const Duration(seconds: 45), (_) => syncFromCloud());

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

  Future<List<Category>> all() async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    if (_cachedCategories != null) {
      return List<Category>.unmodifiable(_cachedCategories!);
    }
    final rows = await _fetch();
    _cachedCategories = rows;
    return rows;
  }

  Future<List<Category>> _fetch() async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return [];
    final res = await db
        .from(_tbl)
        .select()
        .eq('business_id', bizId)
        .isFilter('deleted_at', null)
        .order('name', ascending: true);
    final rows = List<Map<String, dynamic>>.from(res as List);
    final parsed = rows.map(Category.fromJson).toList();
    _cachedCategories = parsed;
    return parsed;
  }

  Future<void> add(String name, {bool isService = false}) async {
    final bizId = await _ensureBizId();
    if (bizId.isEmpty) return;
    final existing = await db
        .from(_tbl)
        .select('id')
        .eq('business_id', bizId)
        .eq('name', name)
        .maybeSingle();
    if (existing != null) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final newCat = Category()
      ..name = name
      ..isService = isService;

    if (_cachedCategories != null) {
      final list = List<Category>.from(_cachedCategories!)..add(newCat);
      list.sort((a, b) => a.name.compareTo(b.name));
      _cachedCategories = list;
      _notifyControllers();
    }

    await db.from(_tbl).insert({
      'business_id': bizId,
      'name': name,
      'is_service': isService,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> delete(String id) async {
    if (_cachedCategories != null) {
      final list = List<Category>.from(_cachedCategories!)
        ..removeWhere((c) => c.uid == id || c.id.toString() == id);
      _cachedCategories = list;
      _notifyControllers();
    }
    await db
        .from(_tbl)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  /// Creates any of [names] that don't already exist (used after onboarding).
  Future<void> seed(List<String> names) async {
    for (final name in names) {
      await add(name, isService: name.toLowerCase() == 'services');
    }
  }
}
