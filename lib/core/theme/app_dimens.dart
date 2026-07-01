import 'package:flutter/widgets.dart';

/// Spacing & shape tokens. Source of truth: AGENT.md → Spacing & Shape.
abstract final class AppDimens {
  static const cardRadius = 14.0;
  static const buttonRadius = 14.0;
  static const pillRadius = 50.0;
  static const inputRadius = 12.0;

  static const cardPadding = EdgeInsets.all(16);
  static const screenPadding = EdgeInsets.symmetric(horizontal: 16);

  static const gap8 = SizedBox(height: 8, width: 8);
  static const gap12 = SizedBox(height: 12, width: 12);
  static const gap16 = SizedBox(height: 16, width: 16);
  static const gap24 = SizedBox(height: 24, width: 24);
}
