import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_text_styles.dart';

/// Theme builder for DC Motorcycle Inventory supporting Light and Dark modes.
abstract final class AppTheme {
  static ThemeData lightTheme(Color accentColor) {
    final base = ThemeData.light(useMaterial3: true);
    
    // Resolve secondary accent color as a darker shade of the main accent
    final accentDark = HSLColor.fromColor(accentColor)
        .withLightness((HSLColor.fromColor(accentColor).lightness - 0.1).clamp(0.0, 1.0))
        .toColor();

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgBaseLight,
      colorScheme: ColorScheme.light(
        surface: AppColors.bgBaseLight,
        surfaceContainer: Colors.white.withValues(alpha: 0.7),
        outlineVariant: Colors.black.withValues(alpha: 0.08),
        primary: accentColor,
        secondary: accentDark,
        error: AppColors.danger,
        onSurface: AppColors.textPrimaryLight,
        onSurfaceVariant: AppColors.textSecondaryLight,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgBaseLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.7),
        hintStyle: const TextStyle(color: AppColors.textMutedLight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.inputRadius),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.inputRadius),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.inputRadius),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: AppColors.textPrimaryLight,
          minimumSize: const Size(64, 48),
          textStyle: AppTextStyles.button,
          splashFactory: InkSparkle.splashFactory,
          animationDuration: const Duration(milliseconds: 140),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          splashFactory: InkSparkle.splashFactory,
          animationDuration: const Duration(milliseconds: 140),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: AppColors.textPrimaryLight,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        disabledColor: Colors.white.withValues(alpha: 0.7),
        selectedColor: accentColor.withValues(alpha: 0.15),
        secondarySelectedColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.pillRadius),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        labelStyle: const TextStyle(color: AppColors.textPrimaryLight),
        secondaryLabelStyle: const TextStyle(color: AppColors.textPrimaryLight),
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: accentColor.withValues(alpha: 0.15),
        circularTrackColor: accentColor.withValues(alpha: 0.15),
      ),
    );
  }

  static ThemeData darkTheme(Color accentColor) {
    final base = ThemeData.dark(useMaterial3: true);
    
    // Resolve secondary accent color as a lighter shade of the main accent
    final accentLight = HSLColor.fromColor(accentColor)
        .withLightness((HSLColor.fromColor(accentColor).lightness + 0.15).clamp(0.0, 1.0))
        .toColor();

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgBase,
      colorScheme: ColorScheme.dark(
        surface: AppColors.bgBase,
        surfaceContainer: AppColors.bgSurface.withValues(alpha: 0.7),
        outlineVariant: Colors.white.withValues(alpha: 0.08),
        primary: accentColor,
        secondary: accentLight,
        error: AppColors.danger,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface.withValues(alpha: 0.7),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.inputRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.inputRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.inputRadius),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(64, 48),
          textStyle: AppTextStyles.button,
          splashFactory: InkSparkle.splashFactory,
          animationDuration: const Duration(milliseconds: 140),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          splashFactory: InkSparkle.splashFactory,
          animationDuration: const Duration(milliseconds: 140),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: AppColors.textPrimary,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgSurface.withValues(alpha: 0.7),
        disabledColor: AppColors.bgSurface.withValues(alpha: 0.7),
        selectedColor: accentColor.withValues(alpha: 0.15),
        secondarySelectedColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.pillRadius),
          side: const BorderSide(color: AppColors.border),
        ),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(color: AppColors.textPrimary),
        brightness: Brightness.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgSurface.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: accentColor.withValues(alpha: 0.15),
        circularTrackColor: accentColor.withValues(alpha: 0.15),
      ),
    );
  }
}
