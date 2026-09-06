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

  Stream<List<Category>> watchAll() {
    final controller = StreamController<List<Category>>.broadcast();
    Future<void> emit() async {
      final rows = await _fetch();
      if (!controller.isClosed) controller.add(rows);
    }

    emit();
    final timer = Timer.periodic(const Duration(seconds: 15), (_) => emit());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  Future<List<Category>> all() => _fetch();

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
    return rows.map(Category.fromJson).toList();
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
    await db.from(_tbl).insert({
      'business_id': bizId,
      'name': name,
      'is_service': isService,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> delete(String id) async {
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
