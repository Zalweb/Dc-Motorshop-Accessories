import 'package:isar_community/isar.dart';

import '../../core/utils/uuid.dart';

part 'product.g.dart';

/// A specific variation of a product (e.g., Color: Black, Size: 28mm).
@embedded
class ProductVariant {
  /// Unique identifier for sync and POS line item tracking.
  String uid = uuidV7();

  /// e.g. "Matte Black / 28mm" or "Red"
  String name = '';

  /// Stock Keeping Unit (e.g. "SHELL-LR-10W40-1L")
  String? sku;

  /// Scannable Barcode (e.g. "9551234567890")
  String? barcode;

  /// Manufacturer Part Number (e.g. "LR10W40-1L")
  String? partNumber;

  /// Option 1 value (e.g. "Matte Black")
  String? option1;

  /// Option 2 value (e.g. "28mm")
  String? option2;

  double costPrice = 0;
  double sellingPrice = 0;
  int stockQty = 0;
  int reorderLevel = 0;
  bool isActive = true;

  /// Local file path to variant-specific image.
  String? imagePath;

  /// Remote URL of variant image.
  String? imageUrl;
}

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

  /// Whether this product uses Shopee-style variants (Color, Size, etc.).
  bool hasVariants = false;

  /// Name of variation 1 (e.g. "Color", "Model").
  String? variation1Name;

  /// Name of variation 2 (e.g. "Size", "Spec").
  String? variation2Name;

  /// List of specific variant combinations.
  List<ProductVariant> variants = [];

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

  @ignore
  int get effectiveStockQty {
    if (!hasVariants || variants.isEmpty) return stockQty;
    return variants.fold(0, (sum, v) => sum + v.stockQty);
  }

  @ignore
  double get minSellingPrice {
    if (!hasVariants || variants.isEmpty) return sellingPrice;
    return variants.map((v) => v.sellingPrice).reduce((a, b) => a < b ? a : b);
  }

  @ignore
  double get maxSellingPrice {
    if (!hasVariants || variants.isEmpty) return sellingPrice;
    return variants.map((v) => v.sellingPrice).reduce((a, b) => a > b ? a : b);
  }
}
