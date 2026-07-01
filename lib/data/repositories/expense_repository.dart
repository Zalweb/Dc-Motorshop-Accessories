import 'package:isar_community/isar.dart';

import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository(this._isar);

  final Isar _isar;

  Stream<List<Expense>> watchAll() =>
      _isar.expenses.where().sortByCreatedAtDesc().watch(fireImmediately: true);

  Future<List<Expense>> between(DateTime start, DateTime end) => _isar.expenses
      .filter()
      .createdAtBetween(start, end)
      .findAll();

  Future<int> save(Expense expense) {
    expense
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    return _isar.writeTxn(() => _isar.expenses.put(expense));
  }

  Future<void> delete(int id) =>
      _isar.writeTxn(() => _isar.expenses.delete(id));
}
