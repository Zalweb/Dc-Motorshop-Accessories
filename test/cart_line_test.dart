import 'package:dc_motorcycle_inventory/features/sales/cart_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CartLine total is unit price times quantity', () {
    final line = CartLine(
      productId: 1,
      productUid: 'test-uid',
      name: 'Brake Pad',
      unitPrice: 380,
      unitCost: 220,
      quantity: 3,
      isService: false,
    );

    expect(line.lineTotal, 1140);
  });
}
