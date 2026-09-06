import 'package:flutter/material.dart';

/// Controller scope providing synchronized shimmer animation down the widget tree.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final bool enabled;

  @override
  State<Shimmer> createState() => _ShimmerState();

  static ShimmerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShimmerScope>();
  }
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Shimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final effectiveEnabled = widget.enabled && !disableAnimations;

    final resolvedBase = widget.baseColor ??
        (isDark ? const Color(0xFF222222) : const Color(0xFFE2E8F0));
    final resolvedHighlight = widget.highlightColor ??
        (isDark ? const Color(0xFF333333) : const Color(0xFFF1F5F9));

    return ShimmerScope(
      animation: _controller,
      baseColor: resolvedBase,
      highlightColor: resolvedHighlight,
      enabled: effectiveEnabled,
      child: widget.child,
    );
  }
}

/// InheritedWidget propagating shimmer parameters and animation to child skeletons.
class ShimmerScope extends InheritedWidget {
  const ShimmerScope({
    super.key,
    required this.animation,
    required this.baseColor,
    required this.highlightColor,
    required this.enabled,
    required super.child,
  });

  final Animation<double> animation;
  final Color baseColor;
  final Color highlightColor;
  final bool enabled;

  @override
  bool updateShouldNotify(ShimmerScope oldWidget) {
    return animation != oldWidget.animation ||
        baseColor != oldWidget.baseColor ||
        highlightColor != oldWidget.highlightColor ||
        enabled != oldWidget.enabled;
  }
}

/// Basic customizable skeleton box that shimmers when wrapped in [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.shape = BoxShape.rectangle,
    this.color,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scope = Shimmer.maybeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackBase = isDark ? const Color(0xFF222222) : const Color(0xFFE2E8F0);
    final baseColor = color ?? scope?.baseColor ?? fallbackBase;
    final highlightColor = scope?.highlightColor ??
        (isDark ? const Color(0xFF333333) : const Color(0xFFF1F5F9));

    if (scope == null || !scope.enabled) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : borderRadius,
        ),
      );
    }

    return AnimatedBuilder(
      animation: scope.animation,
      builder: (context, _) {
        final progress = scope.animation.value;
        final offset = (progress * 3.0) - 1.0;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.circle ? null : borderRadius,
            gradient: LinearGradient(
              begin: Alignment(offset - 1.0, -0.2),
              end: Alignment(offset + 1.0, 0.2),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton text line helper.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

/// Skeleton circle helper (ideal for avatars & icon badges).
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({
    super.key,
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: size,
      height: size,
      shape: BoxShape.circle,
    );
  }
}

/// Card container matching the app's glass/surface design language.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainer,
        borderRadius: borderRadius,
        border: border ??
            Border.all(
              color: isDark
                  ? theme.colorScheme.outlineVariant.withValues(alpha: 0.18)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
      ),
      child: child,
    );
  }
}

/// Skeleton placeholder matching a product item in the Products catalog.
class SkeletonProductRow extends StatelessWidget {
  const SkeletonProductRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      child: const Row(
        children: [
          SkeletonBox(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonLine(width: 130, height: 14),
                SizedBox(height: 6),
                SkeletonLine(width: 80, height: 11),
                SizedBox(height: 6),
                SkeletonLine(width: 50, height: 10),
              ],
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonLine(width: 64, height: 15),
              SizedBox(height: 6),
              SkeletonLine(width: 44, height: 11),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder matching a sale tile in Sales History.
class SkeletonSaleTile extends StatelessWidget {
  const SkeletonSaleTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SkeletonCard(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          // Status bar
          SkeletonBox(
            width: 4,
            height: 36,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(width: 12),
          // Info column
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SkeletonLine(width: 100, height: 14),
                    SizedBox(width: 8),
                    SkeletonBox(
                      width: 48,
                      height: 18,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                SkeletonLine(width: 170, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Price and chevron placeholder
          const SkeletonLine(width: 60, height: 16),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder matching POS product cards in [NewSaleScreen].
class SkeletonPosProductCard extends StatelessWidget {
  const SkeletonPosProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            const Expanded(
              child: SkeletonBox(
                borderRadius: BorderRadius.zero,
              ),
            ),
            // Details area
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SkeletonLine(width: 100, height: 13),
                  const SizedBox(height: 4),
                  const SkeletonLine(width: 60, height: 13),
                  const SizedBox(height: 5),
                  const Row(
                    children: [
                      SkeletonCircle(size: 6),
                      SizedBox(width: 4),
                      SkeletonLine(width: 50, height: 10),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SkeletonBox(
                    height: 36,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder matching MetricCard in the dashboard.
class SkeletonMetricCard extends StatelessWidget {
  const SkeletonMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonBox(
            width: 38,
            height: 38,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(height: 10),
          SkeletonLine(width: 70, height: 11),
          SizedBox(height: 4),
          SkeletonLine(width: 95, height: 18),
        ],
      ),
    );
  }
}

/// Skeleton placeholder matching _SmallMetricCard in the mobile dashboard.
class SkeletonSmallMetricCard extends StatelessWidget {
  const SkeletonSmallMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 420;
    return SkeletonCard(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 12 : 14,
      ),
      borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonCircle(size: 18),
          SizedBox(height: 8),
          SkeletonLine(width: 50, height: 10),
          SizedBox(height: 4),
          SkeletonLine(width: 35, height: 14),
        ],
      ),
    );
  }
}

/// Skeleton placeholder matching the Revenue Hero card on mobile dashboard.
class SkeletonRevenueHero extends StatelessWidget {
  const SkeletonRevenueHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: primary.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLine(width: 130, height: 12),
              SkeletonBox(
                width: 22,
                height: 22,
                shape: BoxShape.circle,
              ),
            ],
          ),
          SizedBox(height: 10),
          SkeletonLine(width: 180, height: 36),
          SizedBox(height: 6),
          SkeletonLine(width: 150, height: 13),
          SizedBox(height: 20),
          // Chart placeholder
          SkeletonBox(
            height: 72,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for the Desktop Revenue Overview Card.
class SkeletonRevenueOverviewCard extends StatelessWidget {
  const SkeletonRevenueOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SkeletonCard(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLine(width: 150, height: 16),
              SkeletonBox(
                width: 70,
                height: 26,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SkeletonBox(
            height: 220,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 18),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 80, height: 11),
                    SizedBox(height: 5),
                    SkeletonLine(width: 100, height: 18),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 80, height: 11),
                    SizedBox(height: 5),
                    SkeletonLine(width: 70, height: 18),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 90, height: 11),
                    SizedBox(height: 5),
                    SkeletonLine(width: 80, height: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for the Desktop Top Selling Products Card.
class SkeletonTopSellingCard extends StatelessWidget {
  const SkeletonTopSellingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLine(width: 160, height: 16),
              SkeletonBox(
                width: 70,
                height: 26,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            const Row(
              children: [
                SkeletonBox(
                  width: 38,
                  height: 38,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SkeletonLine(width: 110, height: 13),
                      SizedBox(height: 4),
                      SkeletonLine(width: 60, height: 11),
                    ],
                  ),
                ),
                SkeletonLine(width: 55, height: 14),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton placeholder for the Desktop KPI Cards row.
class SkeletonKpiCard extends StatelessWidget {
  const SkeletonKpiCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderRadius: BorderRadius.circular(20),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SkeletonBox(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonLine(width: 85, height: 10),
                SizedBox(height: 6),
                SkeletonLine(width: 110, height: 20),
                SizedBox(height: 5),
                SkeletonLine(width: 75, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for donut chart cards (Payment Methods & Transaction Status).
class SkeletonDonutCard extends StatelessWidget {
  const SkeletonDonutCard({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLine(width: 140, height: 16),
              const SkeletonBox(
                width: 60,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Center(
            child: SkeletonCircle(size: 130),
          ),
          const SizedBox(height: 24),
          const Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLine(width: 70, height: 12),
                  SkeletonLine(width: 50, height: 12),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLine(width: 70, height: 12),
                  SkeletonLine(width: 50, height: 12),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for Low Stock Alert card on desktop.
class SkeletonLowStockCard extends StatelessWidget {
  const SkeletonLowStockCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLine(width: 130, height: 16),
              SkeletonBox(
                width: 50,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            const Row(
              children: [
                SkeletonBox(
                  width: 36,
                  height: 36,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(width: 90, height: 13),
                      SizedBox(height: 4),
                      SkeletonLine(width: 50, height: 11),
                    ],
                  ),
                ),
                SkeletonBox(
                  width: 55,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

