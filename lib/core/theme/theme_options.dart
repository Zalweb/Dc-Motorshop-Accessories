import 'package:flutter/material.dart';

/// Selectable accent themes shown on the onboarding theme picker (reference
/// 4.jpg). Default is Blue. The chosen name is stored in BusinessSettings.
class ThemeOption {
  const ThemeOption(this.name, this.color);
  final String name;
  final Color color;
}

const kThemeOptions = <ThemeOption>[
  ThemeOption('Green', Color(0xFF22C55E)),
  ThemeOption('Blue', Color(0xFF2563EB)),
  ThemeOption('Purple', Color(0xFF8B5CF6)),
  ThemeOption('Orange', Color(0xFFF97316)),
  ThemeOption('Rose', Color(0xFFF43F5E)),
  ThemeOption('Slate', Color(0xFF64748B)),
  ThemeOption('Teal', Color(0xFF14B8A6)),
  ThemeOption('Indigo', Color(0xFF6366F1)),
  ThemeOption('Amber', Color(0xFFF59E0B)),
  ThemeOption('Cyan', Color(0xFF06B6D4)),
];
