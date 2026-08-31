import 'package:isar_community/isar.dart';

import '../models/inventory_transaction.dart';

class InventoryRepository {
  InventoryRepository(this._isar);

  final Isar _isar;

  Stream<List<InventoryTransaction>> watchRecent({int limit = 50}) => _isar
      .inventoryTransactions
      .where()
      .sortByCreatedAtDesc()
      .limit(limit)
      .watch(fireImmediately: true);

  Future<List<InventoryTransaction>> all() => _isar.inventoryTransactions
      .where()
      .sortByCreatedAtDesc()
      .findAll();

  Future<List<InventoryTransaction>> byVariantUid(String variantUid) => _isar
      .inventoryTransactions
      .filter()
      .productVariantUidEqualTo(variantUid)
      .sortByCreatedAtDesc()
      .findAll();

  Future<int> record(InventoryTransaction tx) {
    tx
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    return _isar.writeTxn(() => _isar.inventoryTransactions.put(tx));
  }

  Future<void> recordBatch(List<InventoryTransaction> transactions) {
    for (final tx in transactions) {
      tx
        ..updatedAt = DateTime.now()
        ..isDirty = true;
    }
    return _isar.writeTxn(() => _isar.inventoryTransactions.putAll(transactions));
  }
}
