// ─────────────────────────────────────────────────────────────────────────────
// Web-safe model: Expense (no isar annotations, no part directive)
// ─────────────────────────────────────────────────────────────────────────────
import '../../core/utils/uuid.dart';

/// A business expense — web-safe mirror of native [Expense].
class Expense {
  Expense({
    String? uid,
    this.label = '',
    this.amount = 0,
    this.note,
    this.type = 'variable',
    this.category,
    this.frequency,
    this.endDate,
    this.includeInCalculations = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDirty = true,
  })  : uid = uid ?? uuidV7(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Surrogate for Isar integer id. Unused on web.
  int id = 0;

  String uid;
  String label;
  double amount;
  String? note;
  String type;
  String? category;
  String? frequency;
  DateTime? endDate;
  bool includeInCalculations;
  DateTime createdAt;
  DateTime updatedAt;
  bool isDirty;

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        uid: j['id'] as String? ?? j['uid'] as String? ?? uuidV7(),
        label: j['label'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        note: j['note'] as String?,
        type: j['type'] as String? ?? 'variable',
        category: j['category'] as String?,
        frequency: j['frequency'] as String?,
        endDate: j['end_date'] != null
            ? DateTime.parse(j['end_date'] as String)
            : null,
        includeInCalculations:
            j['include_in_calculations'] as bool? ?? true,
        createdAt: j['created_at'] != null
            ? DateTime.parse(j['created_at'] as String)
            : DateTime.now(),
        updatedAt: j['updated_at'] != null
            ? DateTime.parse(j['updated_at'] as String)
            : DateTime.now(),
        isDirty: false,
      );

  Map<String, dynamic> toJson() => {
        'id': uid,
        'label': label,
        'amount': amount,
        if (note != null) 'note': note,
        'type': type,
        if (category != null) 'category': category,
        if (frequency != null) 'frequency': frequency,
        if (endDate != null) 'end_date': endDate!.toIso8601String(),
        'include_in_calculations': includeInCalculations,
        'updated_at': updatedAt.toIso8601String(),
      };
}
