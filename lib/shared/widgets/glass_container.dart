import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glassmorphic container card.
/// Combines backdrop blur, translucent fill, and fine border outline.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.height,
    this.width,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final double? height;
  final double? width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final radius = borderRadius ?? BorderRadius.circular(16);
    
    return Container(
      margin: margin,
      height: height,
      width: width,
      decoration: BoxDecoration(
        // Subtle floating shadow for premium look
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? theme.colorScheme.surfaceContainer,
              borderRadius: radius,
              border: border ?? Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
