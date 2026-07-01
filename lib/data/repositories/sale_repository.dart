import 'package:isar_community/isar.dart';

import '../models/sale.dart';

class SaleRepository {
  SaleRepository(this._isar);

  final Isar _isar;

  Stream<List<Sale>> watchAll() =>
      _isar.sales.where().sortByCreatedAtDesc().watch(fireImmediately: true);

  Future<List<Sale>> all() =>
      _isar.sales.where().sortByCreatedAtDesc().findAll();

  Future<List<Sale>> between(DateTime start, DateTime end) => _isar.sales
      .filter()
      .createdAtBetween(start, end)
      .sortByCreatedAtDesc()
      .findAll();

  Future<int> save(Sale sale) {
    sale
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    return _isar.writeTxn(() => _isar.sales.put(sale));
  }

  /// Generates the next human-friendly sale number, e.g. "S-0001".
  Future<String> nextSaleNumber() async {
    final count = await _isar.sales.count();
    return 'S-${(count + 1).toString().padLeft(4, '0')}';
  }
}
