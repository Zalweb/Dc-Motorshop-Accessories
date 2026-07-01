import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens. Source of truth: AGENT.md → Design System → Typography.
/// Colors are omitted so they inherit automatically from the active theme.
abstract final class AppTextStyles {
  static final headingLarge = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  static final headingMedium = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  static final labelCaps = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static final body = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static final bodySmall = GoogleFonts.inter(
    fontSize: 13,
  );

  static final button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
}
