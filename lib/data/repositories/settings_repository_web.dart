import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business_settings_web.dart';

/// Web-safe, Supabase-backed business-settings repository (cloud-only).
class SettingsRepositoryWeb {
  SettingsRepositoryWeb({required this.db});

  final SupabaseClient db;

  Stream<BusinessSettings?> watch() {
    final controller = StreamController<BusinessSettings?>.broadcast();
    Future<void> emit() async {
      final s = await getOrCreate();
      if (!controller.isClosed) controller.add(s);
    }

    emit();
    final timer = Timer.periodic(const Duration(seconds: 20), (_) => emit());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  Future<BusinessSettings?> _fetch() async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await db
        .from('business_profiles')
        .select()
        .eq('owner_id', uid)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (res == null) return null;
    return BusinessSettings.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<BusinessSettings> getOrCreate() async {
    final s = await _fetch();
    return s ?? BusinessSettings();
  }

  Future<void> save(BusinessSettings settings) async {
    settings
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    final ownerId = db.auth.currentUser?.id;
    if (ownerId == null) return;
    final row = settings.toJson()
      ..['owner_id'] = ownerId
      ..['updated_at'] = settings.updatedAt.toUtc().toIso8601String();
    await db.from('business_profiles').upsert(row, onConflict: 'id');
  }

  Future<void> update(void Function(BusinessSettings) mutate) async {
    final settings = await getOrCreate();
    mutate(settings);
    await save(settings);
  }
}
