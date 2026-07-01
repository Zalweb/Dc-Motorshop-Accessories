import 'package:isar_community/isar.dart';

import '../../core/utils/uuid.dart';

part 'product.g.dart';

/// A motorcycle part, accessory, or service the shop sells.
@collection
class Product {
  Id id = Isar.autoIncrement;

  /// Server-aligned UUID v7 — the canonical id used by the API and sync.
  @Index(unique: true)
  String uid = uuidV7();

  late String name;

  @Index()
  String? barcode;

  String? category;
  String? description;

  // Product details.
  String? partNumber;
  String? brand;
  String unit = 'piece';

  /// True for labor/services (no stock tracking), false for physical goods.
  bool isService = false;

  double costPrice = 0;
  double sellingPrice = 0;
  int stockQty = 0;

  /// Local file path to the picked image.
  String? imagePath;

  /// Object key / signed URL returned by the backend after upload.
  String? imageUrl;

  DateTime createdAt = DateTime.now();

  // Sync metadata.
  DateTime updatedAt = DateTime.now();
  bool isDirty = true;
}
