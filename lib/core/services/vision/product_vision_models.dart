/// Represents the structured data extracted by the Product Vision scanner.
class ProductVisionResult {
  final String? name;
  final String? brand;
  final String? partNumber;
  final String? category;
  final double? sellingPrice;
  final double? costPrice;
  final String? barcode;
  final String? description;
  final String? imagePath;
  final String? rawText;
  final double confidence;

  const ProductVisionResult({
    this.name,
    this.brand,
    this.partNumber,
    this.category,
    this.sellingPrice,
    this.costPrice,
    this.barcode,
    this.description,
    this.imagePath,
    this.rawText,
    this.confidence = 1.0,
  });

  ProductVisionResult copyWith({
    String? name,
    String? brand,
    String? partNumber,
    String? category,
    double? sellingPrice,
    double? costPrice,
    String? barcode,
    String? description,
    String? imagePath,
    String? rawText,
    double? confidence,
  }) {
    return ProductVisionResult(
      name: name ?? this.name,
      brand: brand ?? this.brand,
      partNumber: partNumber ?? this.partNumber,
      category: category ?? this.category,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
    );
  }
}
