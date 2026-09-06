import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/motion_controller.dart';

/// Staggered cascade entrance widget:
/// - Each child animates a slide-up from [Offset(0, 0.06)] to [Offset.zero] plus fade-in.
/// - Starts [delayStep] * index after first frame, [Curves.easeOutCubic] forward only.
/// - When motion is disabled via [motionEnabledProvider], renders children directly.
/// - Also provides static helper [StaggeredEntrance.wrapIndexed] for manual layouts.
class StaggeredEntrance extends ConsumerStatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.children,
    this.delayStep = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 280),
    this.initialOffset = const Offset(0, 0.06),
    this.curve = Curves.easeOutCubic,
    this.axis = Axis.vertical,
    this.mainAxisSize = MainAxisSize.min,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final Duration delayStep;
  final Duration duration;
  final Offset initialOffset;
  final Curve curve;
  final Axis axis;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  /// Helper to wrap a single child with a staggered entrance given its index.
  /// Useful for manual layouts (e.g. Columns, Grids, or Row items).
  static Widget wrapIndexed({
    required BuildContext context,
    required int index,
    required Widget child,
    Duration delayStep = const Duration(milliseconds: 60),
    Duration duration = const Duration(milliseconds: 280),
    Offset initialOffset = const Offset(0, 0.06),
    Curve curve = Curves.easeOutCubic,
  }) {
    return _SingleStaggeredItem(
      index: index,
      delayStep: delayStep,
      duration: duration,
      initialOffset: initialOffset,
      curve: curve,
      child: child,
    );
  }

  @override
  ConsumerState<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends ConsumerState<StaggeredEntrance> {
  @override
  Widget build(BuildContext context) {
    final motionEnabled = ref.watch(motionEnabledProvider);

    if (!motionEnabled) {
      return widget.axis == Axis.vertical
          ? Column(
              mainAxisSize: widget.mainAxisSize,
              mainAxisAlignment: widget.mainAxisAlignment,
              crossAxisAlignment: widget.crossAxisAlignment,
              children: widget.children,
            )
          : Row(
              mainAxisSize: widget.mainAxisSize,
              mainAxisAlignment: widget.mainAxisAlignment,
              crossAxisAlignment: widget.crossAxisAlignment,
              children: widget.children,
            );
    }

    final wrappedChildren = List<Widget>.generate(
      widget.children.length,
      (index) => _SingleStaggeredItem(
        index: index,
        delayStep: widget.delayStep,
        duration: widget.duration,
        initialOffset: widget.initialOffset,
        curve: widget.curve,
        child: widget.children[index],
      ),
    );

    return widget.axis == Axis.vertical
        ? Column(
            mainAxisSize: widget.mainAxisSize,
            mainAxisAlignment: widget.mainAxisAlignment,
            crossAxisAlignment: widget.crossAxisAlignment,
            children: wrappedChildren,
          )
        : Row(
            mainAxisSize: widget.mainAxisSize,
            mainAxisAlignment: widget.mainAxisAlignment,
            crossAxisAlignment: widget.crossAxisAlignment,
            children: wrappedChildren,
          );
  }
}

class _SingleStaggeredItem extends ConsumerStatefulWidget {
  const _SingleStaggeredItem({
    required this.index,
    required this.delayStep,
    required this.duration,
    required this.initialOffset,
    required this.curve,
    required this.child,
  });

  final int index;
  final Duration delayStep;
  final Duration duration;
  final Offset initialOffset;
  final Curve curve;
  final Widget child;

  @override
  ConsumerState<_SingleStaggeredItem> createState() => _SingleStaggeredItemState();
}

class _SingleStaggeredItemState extends ConsumerState<_SingleStaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: widget.initialOffset,
      end: Offset.zero,
    ).animate(curved);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final delay = widget.delayStep * widget.index;
      if (delay == Duration.zero) {
        _controller.forward();
      } else {
        Future.delayed(delay, () {
          if (mounted) _controller.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motionEnabled = ref.watch(motionEnabledProvider);
    if (!motionEnabled) {
      return widget.child;
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}
