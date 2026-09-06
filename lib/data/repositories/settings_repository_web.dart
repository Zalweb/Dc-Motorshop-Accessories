import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business_settings_web.dart';

/// Web-safe, Supabase-backed business-settings repository (cloud-only).
class SettingsRepositoryWeb {
  SettingsRepositoryWeb({required this.db});

  final SupabaseClient db;

  static BusinessSettings? _cachedSettings;
  static final List<StreamController<BusinessSettings?>> _controllers = [];
  static Timer? _pollTimer;
  static bool _isFetching = false;

  static void clearCache() {
    _cachedSettings = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _isFetching = false;
  }

  static void _notifyControllers() {
    if (_cachedSettings == null) return;
    for (final c in List.of(_controllers)) {
      if (!c.isClosed) c.add(_cachedSettings);
    }
  }

  static bool _settingsEqual(BusinessSettings? a, BusinessSettings? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.businessName == b.businessName &&
        a.themeColor == b.themeColor &&
        a.currency == b.currency &&
        a.logoPath == b.logoPath &&
        a.includeUnpaidInReports == b.includeUnpaidInReports &&
        a.allowSellWhenOutOfStock == b.allowSellWhenOutOfStock &&
        a.updatedAt == b.updatedAt;
  }

  Stream<BusinessSettings?> watch() {
    final controller = StreamController<BusinessSettings?>.broadcast();
    _controllers.add(controller);

    if (_cachedSettings != null) {
      controller.add(_cachedSettings);
    }

    Future<void> syncFromCloud() async {
      if (_isFetching) return;
      _isFetching = true;
      try {
        final s = await getOrCreate();
        if (!_settingsEqual(_cachedSettings, s)) {
          _cachedSettings = s;
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
    final parsed = BusinessSettings.fromJson(Map<String, dynamic>.from(res as Map));
    _cachedSettings = parsed;
    return parsed;
  }

  Future<BusinessSettings> getOrCreate() async {
    final s = await _fetch();
    return s ?? _cachedSettings ?? BusinessSettings();
  }

  Future<void> save(BusinessSettings settings) async {
    settings
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    _cachedSettings = settings;
    _notifyControllers();

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
