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

  Future<Product?> findByBarcode(String barcode) =>
      _isar.products.filter().barcodeEqualTo(barcode).findFirst();

  Future<int> save(Product product) {
    product
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    return _isar.writeTxn(() => _isar.products.put(product));
  }

  Future<void> delete(int id) =>
      _isar.writeTxn(() => _isar.products.delete(id));

  /// Reduces stock for a sold product (no-op for services).
  Future<void> decrementStock(int productId, int qty) async {
    final product = await _isar.products.get(productId);
    if (product == null || product.isService) return;
    product
      ..stockQty = (product.stockQty - qty).clamp(0, 1 << 31)
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    await _isar.writeTxn(() => _isar.products.put(product));
  }
}
