import 'package:dc_motorcycle_inventory/core/utils/uuid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uuidV7 has the canonical 8-4-4-4-12 shape', () {
    final value = uuidV7();
    expect(
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
          .hasMatch(value),
      isTrue,
    );
  });

  test('uuidV7 sets the version 7 nibble', () {
    final value = uuidV7();
    expect(value[14], '7');
  });

  test('uuidV7 values are unique', () {
    final values = {for (var i = 0; i < 1000; i++) uuidV7()};
    expect(values.length, 1000);
  });
}
