import 'package:flutter/material.dart';

import 'app_image.dart';
import 'brand_mark.dart';

/// Universal Shop Logo widget that renders custom business logos or falls back
/// cleanly to the BrandMark. Seamless in both Dark Mode and Light Mode with
/// full support for transparent PNGs and base64 data URIs.
class ShopLogo extends StatelessWidget {
  const ShopLogo({
    super.key,
    this.logoPath,
    this.size = 56,
    this.borderRadius,
    this.fit = BoxFit.contain,
    this.showFallbackBrandMark = true,
  });

  final String? logoPath;
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final bool showFallbackBrandMark;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(size * 0.22);
    final trimmed = (logoPath ?? '').trim();

    if (trimmed.isEmpty) {
      if (showFallbackBrandMark) {
        return BrandMark(size: size);
      }
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: effectiveRadius,
        ),
        child: Icon(
          Icons.store_rounded,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: AppImage(
          imageUrl: trimmed,
          imagePath: trimmed,
          width: size,
          height: size,
          fit: fit,
          borderRadius: effectiveRadius,
          placeholderIcon: Icons.store_rounded,
          placeholderIconSize: size * 0.5,
        ),
      ),
    );
  }
}
