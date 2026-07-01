import 'package:isar_community/isar.dart';

import '../models/category.dart';
import '../models/expense.dart';
import '../models/product.dart';
import '../models/sale.dart';

/// Destructive local-data operations for the Advanced settings card.
class MaintenanceRepository {
  MaintenanceRepository(this._isar);

  final Isar _isar;

  /// Wipes business data (catalog, sales, expenses) but keeps the signed-in
  /// account and business settings.
  Future<void> resetLocalData() => _isar.writeTxn(() async {
        await _isar.collection<Product>().clear();
        await _isar.collection<Category>().clear();
        await _isar.collection<Sale>().clear();
        await _isar.collection<Expense>().clear();
      });

  /// Wipes every local collection, including the account and settings. Used by
  /// "Delete account" before signing out.
  Future<void> deleteAllLocal() => _isar.writeTxn(() => _isar.clear());
}
