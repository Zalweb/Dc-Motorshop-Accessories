import 'package:dc_motorcycle_inventory/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatPeso renders a peso amount with two decimals and grouping', () {
    expect(formatPeso(1234.5), '₱1,234.50');
  });
}
