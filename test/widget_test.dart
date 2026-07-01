import 'package:dc_motorcycle_inventory/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PrimaryButton renders its label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(label: 'Sign in', onPressed: () {}),
        ),
      ),
    );

    expect(find.text('Sign in'), findsOneWidget);
  });
}
