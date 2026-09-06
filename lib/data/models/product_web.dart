// ─────────────────────────────────────────────────────────────────────────────
// Web-safe model: Product (no isar annotations, no part directive)
// Mirrors every public field of the native Product / ProductVariant so that
// all UI code reading those fields compiles on web without modification.
// ─────────────────────────────────────────────────────────────────────────────
import '../../core/utils/uuid.dart';

/// A specific variation of a product — web-safe mirror of [ProductVariant].
class ProductVariant {
  ProductVariant({
    String? uid,
    this.name = '',
    this.sku,
    this.barcode,
    this.partNumber,
    this.option1,
    this.option2,
    this.costPrice = 0,
    this.sellingPrice = 0,
    this.stockQty = 0,
    this.reorderLevel = 0,
    this.isActive = true,
    this.imagePath,
    this.imageUrl,
  }) : uid = uid ?? uuidV7();

  String uid;
  String name;
  String? sku;
  String? barcode;
  String? partNumber;
  String? option1;
  String? option2;
  double costPrice;
  double sellingPrice;
  int stockQty;
  int reorderLevel;
  bool isActive;
  String? imagePath;
  String? imageUrl;

  factory ProductVariant.fromJson(Map<String, dynamic> j) => ProductVariant(
        uid: j['uid'] as String? ?? j['id'] as String? ?? uuidV7(),
        name: j['name'] as String? ?? j['variant_name'] as String? ?? '',
        sku: j['sku'] as String?,
        barcode: j['barcode'] as String?,
        partNumber: j['part_number'] as String?,
        option1: j['option1'] as String? ?? j['option1_value'] as String?,
        option2: j['option2'] as String? ?? j['option2_value'] as String?,
        costPrice: (j['cost_price'] as num?)?.toDouble() ?? 0,
        sellingPrice: (j['selling_price'] as num?)?.toDouble() ?? 0,
        stockQty: ((j['stock_on_hand'] ?? j['stock_qty']) as num?)?.toInt() ?? 0,
        reorderLevel: ((j['reorder_level'] ?? j['reorder_point']) as num?)?.toInt() ?? 0,
        isActive: j['is_active'] as bool? ?? true,
        imagePath: j['image_path'] as String?,
        imageUrl: j['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        if (sku != null) 'sku': sku,
        if (barcode != null) 'barcode': barcode,
        if (partNumber != null) 'part_number': partNumber,
        if (option1 != null) 'option1': option1,
        if (option2 != null) 'option2': option2,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock_qty': stockQty,
        'stock_on_hand': stockQty,
        'reorder_level': reorderLevel,
        'is_active': isActive,
        if (imagePath != null) 'image_path': imagePath,
        if (imageUrl != null) 'image_url': imageUrl,
      };
}

/// A motorcycle part, accessory, or service — web-safe mirror of [Product].
class Product {
  Product({
    String? uid,
    this.name = '',
    this.barcode,
    this.category,
    this.description,
    this.partNumber,
    this.brand,
    this.unit = 'piece',
    this.isService = false,
    this.hasVariants = false,
    this.variation1Name,
    this.variation2Name,
    List<ProductVariant>? variants,
    this.costPrice = 0,
    this.sellingPrice = 0,
    this.stockQty = 0,
    this.imagePath,
    this.imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDirty = true,
  })  : uid = uid ?? uuidV7(),
        variants = variants ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Surrogate for Isar's integer id. Generates a stable positive 31-bit integer
  /// from the UID so cart, detail routes, and line item tracking work seamlessly on web.
  int get id => _id ?? (uid.hashCode & 0x7FFFFFFF);
  set id(int val) => _id = val;
  int? _id;

  String uid;
  String name;
  String? barcode;
  String? category;
  String? description;
  String? partNumber;
  String? brand;
  String unit;
  bool isService;
  bool hasVariants;
  String? variation1Name;
  String? variation2Name;
  List<ProductVariant> variants;
  double costPrice;
  double sellingPrice;
  int stockQty;
  String? imagePath;
  String? imageUrl;
  DateTime createdAt;
  DateTime updatedAt;
  bool isDirty;

  int get effectiveStockQty {
    if (!hasVariants || variants.isEmpty) return stockQty;
    return variants.fold(0, (sum, v) => sum + v.stockQty);
  }

  double get minSellingPrice {
    if (!hasVariants || variants.isEmpty) return sellingPrice;
    return variants.map((v) => v.sellingPrice).reduce((a, b) => a < b ? a : b);
  }

  double get maxSellingPrice {
    if (!hasVariants || variants.isEmpty) return sellingPrice;
    return variants.map((v) => v.sellingPrice).reduce((a, b) => a > b ? a : b);
  }

  factory Product.fromJson(Map<String, dynamic> j) {
    final variantsJson =
        (j['variants'] ?? j['product_variants']) as List<dynamic>? ?? [];
    return Product(
      uid: j['id'] as String? ?? j['uid'] as String? ?? uuidV7(),
      name: j['name'] as String? ?? '',
      barcode: j['barcode'] as String?,
      category: j['category_name'] as String? ??
          (j['categories'] is Map
              ? (j['categories'] as Map)['name'] as String?
              : null) ??
          j['category'] as String? ??
          j['category_id'] as String?,
      description: j['description'] as String?,
      partNumber: j['part_number'] as String?,
      brand: j['brand'] as String?,
      unit: j['unit'] as String? ?? 'piece',
      isService: j['is_service'] as bool? ?? false,
      hasVariants: j['has_variants'] as bool? ?? false,
      variation1Name: j['variation1_name'] as String?,
      variation2Name: j['variation2_name'] as String?,
      variants: variantsJson
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
      costPrice: (j['cost_price'] as num?)?.toDouble() ?? 0,
      sellingPrice: (j['selling_price'] as num?)?.toDouble() ?? 0,
      stockQty: ((j['stock_on_hand'] ?? j['stock_qty']) as num?)?.toInt() ?? 0,
      imagePath: j['image_path'] as String?,
      imageUrl: j['image_url'] as String?,
      createdAt: j['created_at'] != null
          ? DateTime.parse(j['created_at'] as String)
          : DateTime.now(),
      updatedAt: j['updated_at'] != null
          ? DateTime.parse(j['updated_at'] as String)
          : DateTime.now(),
      isDirty: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': uid,
        'name': name,
        if (barcode != null) 'barcode': barcode,
        if (category != null) 'category_id': category,
        if (description != null) 'description': description,
        if (partNumber != null) 'part_number': partNumber,
        if (brand != null) 'brand': brand,
        'unit': unit,
        'is_service': isService,
        'has_variants': hasVariants,
        if (variation1Name != null) 'variation1_name': variation1Name,
        if (variation2Name != null) 'variation2_name': variation2Name,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock_on_hand': stockQty,
        'stock_qty': stockQty,
        'variants': variants.map((v) => v.toJson()).toList(),
        if (imagePath != null) 'image_path': imagePath,
        if (imageUrl != null) 'image_url': imageUrl,
        'updated_at': updatedAt.toIso8601String(),
      };
}
