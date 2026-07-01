import 'package:isar_community/isar.dart';

import '../models/category.dart';

class CategoryRepository {
  CategoryRepository(this._isar);

  final Isar _isar;

  Stream<List<Category>> watchAll() =>
      _isar.categorys.where().sortByName().watch(fireImmediately: true);

  Future<List<Category>> all() => _isar.categorys.where().sortByName().findAll();

  Future<void> add(String name, {bool isService = false}) async {
    final exists = await _isar.categorys
        .filter()
        .nameEqualTo(name, caseSensitive: false)
        .findFirst();
    if (exists != null) return;
    final category = Category()
      ..name = name
      ..isService = isService;
    await _isar.writeTxn(() => _isar.categorys.put(category));
  }

  Future<void> delete(int id) =>
      _isar.writeTxn(() => _isar.categorys.delete(id));

  /// Creates any of [names] that don't already exist (used after onboarding).
  Future<void> seed(List<String> names) async {
    for (final name in names) {
      await add(name, isService: name.toLowerCase() == 'services');
    }
  }
}
