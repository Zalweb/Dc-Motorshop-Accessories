import '../../data/models/product.dart';

/// A pending bulk-add entry. Nothing is written to the database until the user
/// confirms with the "Add products" button.
class BulkQueueItem {
  BulkQueueItem.newProduct(this.draft)
      : existing = null,
        restockQty = 0;
  BulkQueueItem.restock(this.existing)
      : draft = null,
        restockQty = 1;

  /// A brand-new product to insert on confirm.
  final Product? draft;

  /// An existing product to restock on confirm.
  final Product? existing;

  /// Units to add to [existing]'s stock on confirm.
  int restockQty;

  bool get isRestock => existing != null;

  Product get product => existing ?? draft!;

  String get name => product.name;

  String? get barcode => product.barcode;

  /// Whether a quantity stepper makes sense (services don't track stock).
  bool get canEditQuantity => isRestock || !draft!.isService;

  /// Units this entry represents: restock amount for an existing product, or
  /// the new draft's starting stock.
  int get quantity => isRestock ? restockQty : draft!.stockQty;

  set quantity(int value) {
    final clamped = value.clamp(1, 1 << 31);
    if (isRestock) {
      restockQty = clamped;
    } else {
      draft!.stockQty = clamped;
    }
  }
}
