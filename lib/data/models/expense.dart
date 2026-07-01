import 'package:isar_community/isar.dart';

import '../../core/utils/uuid.dart';

part 'expense.g.dart';

/// A business expense (rent, utilities, supplies). Feeds net profit on the
/// dashboard.
@collection
class Expense {
  Id id = Isar.autoIncrement;

  /// Server-aligned UUID v7 — the canonical id used by the API and sync.
  @Index(unique: true)
  String uid = uuidV7();

  late String label;
  double amount = 0;
  String? note;
  String type = 'variable';

  String? category;
  String? frequency;
  DateTime? endDate;
  bool includeInCalculations = true;

  @Index()
  DateTime createdAt = DateTime.now();

  // Sync metadata.
  DateTime updatedAt = DateTime.now();
  bool isDirty = true;
}
