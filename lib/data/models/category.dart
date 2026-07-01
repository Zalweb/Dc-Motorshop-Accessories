import 'package:isar_community/isar.dart';

import '../../core/utils/uuid.dart';

part 'category.g.dart';

/// A product/service category (e.g. Engine Parts, Brakes, Services).
@collection
class Category {
  Id id = Isar.autoIncrement;

  /// Server-aligned UUID v7 — the canonical id used by the API and sync.
  @Index(unique: true)
  String uid = uuidV7();

  @Index(unique: true, caseSensitive: false)
  late String name;

  /// Services group under the SERVICES filter; everything else under PRODUCTS.
  bool isService = false;

  DateTime createdAt = DateTime.now();

  // Sync metadata.
  DateTime updatedAt = DateTime.now();
  bool isDirty = true;
}
