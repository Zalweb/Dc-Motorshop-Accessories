// ─────────────────────────────────────────────────────────────────────────────
// Web-safe model: Category (no isar annotations, no part directive)
// ─────────────────────────────────────────────────────────────────────────────
import '../../core/utils/uuid.dart';

/// A product/service category — web-safe mirror of native [Category].
class Category {
  Category({
    String? uid,
    this.name = '',
    this.isService = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDirty = true,
  })  : uid = uid ?? uuidV7(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Surrogate for Isar integer id. Unused on web.
  int id = 0;

  String uid;
  String name;
  bool isService;
  DateTime createdAt;
  DateTime updatedAt;
  bool isDirty;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        uid: j['id'] as String? ?? j['uid'] as String? ?? uuidV7(),
        name: j['name'] as String? ?? '',
        isService: j['is_service'] as bool? ?? false,
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
        'name': name,
        'is_service': isService,
        'updated_at': updatedAt.toIso8601String(),
      };
}
