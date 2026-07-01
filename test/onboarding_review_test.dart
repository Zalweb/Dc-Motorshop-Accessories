import 'package:dc_motorcycle_inventory/features/onboarding/step2_review_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Review setup step shows the default categories', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OnboardingReviewSetupScreen()),
      ),
    );

    expect(find.text('Parts'), findsOneWidget);
  });
}
