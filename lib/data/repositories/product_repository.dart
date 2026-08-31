import 'package:isar_community/isar.dart';

import '../models/product.dart';

class ProductRepository {
  ProductRepository(this._isar);

  final Isar _isar;

  Stream<List<Product>> watchAll() => _isar.products
      .where()
      .sortByCreatedAtDesc()
      .watch(fireImmediately: true);

  Future<List<Product>> all() =>
      _isar.products.where().sortByCreatedAtDesc().findAll();

  Future<Product?> byId(int id) => _isar.products.get(id);

  Future<Product?> findByBarcode(String code) async {
    final clean = code.trim();
    if (clean.isEmpty) return null;

    final direct = await _isar.products
        .filter()
        .barcodeEqualTo(clean)
        .or()
        .partNumberEqualTo(clean)
        .findFirst();
    if (direct != null) return direct;

    final withVariants =
        await _isar.products.filter().hasVariantsEqualTo(true).findAll();
    for (final p in withVariants) {
      if (p.variants.any((v) =>
          v.barcode == clean ||
          v.sku == clean ||
          v.partNumber == clean)) {
        return p;
      }
    }
    return null;
  }

  Future<int> save(Product product) {
    product
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    return _isar.writeTxn(() => _isar.products.put(product));
  }

  Future<void> delete(int id) =>
      _isar.writeTxn(() => _isar.products.delete(id));

  /// Reduces stock for a sold product or specific variant (no-op for services).
  Future<void> decrementStock(int productId, int qty, {String? variantUid}) async {
    final product = await _isar.products.get(productId);
    if (product == null || product.isService) return;
    if (product.hasVariants && variantUid != null) {
      final updated = <ProductVariant>[];
      for (final v in product.variants) {
        if (v.uid == variantUid) {
          v.stockQty = (v.stockQty - qty).clamp(0, 1 << 31);
        }
        updated.add(v);
      }
      product.variants = updated;
      product.stockQty = product.effectiveStockQty;
    } else {
      product.stockQty = (product.stockQty - qty).clamp(0, 1 << 31);
    }
    product
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    await _isar.writeTxn(() => _isar.products.put(product));
  }
}
