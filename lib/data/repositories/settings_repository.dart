import 'package:isar_community/isar.dart';

import '../models/business_settings.dart';

/// Reads and writes the single BusinessSettings record.
class SettingsRepository {
  SettingsRepository(this._isar);

  final Isar _isar;

  Future<BusinessSettings> getOrCreate() async {
    final existing = await _isar.businessSettings.get(BusinessSettings.singletonId);
    if (existing != null) return existing;
    final settings = BusinessSettings();
    await _isar.writeTxn(() => _isar.businessSettings.put(settings));
    return settings;
  }

  Future<void> save(BusinessSettings settings) {
    settings
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    return _isar.writeTxn(() => _isar.businessSettings.put(settings));
  }

  /// Loads the settings, applies [mutate], and persists in one step.
  Future<void> update(void Function(BusinessSettings) mutate) async {
    final settings = await getOrCreate();
    mutate(settings);
    await save(settings);
  }

  Stream<BusinessSettings?> watch() => _isar.businessSettings
      .watchObject(BusinessSettings.singletonId, fireImmediately: true);
}
