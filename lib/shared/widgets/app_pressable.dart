import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/motion_controller.dart';

/// Generic pressable interaction widget that wraps any child with micro-motion:
/// - Press: scales down to 0.96 in 120ms (Curves.easeOutCubic)
/// - Release: springs back in 220ms (Curves.easeOutBack)
/// - Hover: lifts to 1.02 on desktop / web pointer hover
/// - Motion safety: respects [motionEnabledProvider] and passes through unscaled if disabled
/// - Gesture transparency: uses [Listener] onPointerDown/onPointerUp/onPointerCancel
///   so child InkWell, GestureDetector, or button ripples still work smoothly.
class AppPressable extends ConsumerStatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.cursor = SystemMouseCursors.click,
    this.scaleDown = 0.96,
    this.hoverScale = 1.02,
    this.pressDuration = const Duration(milliseconds: 120),
    this.releaseDuration = const Duration(milliseconds: 220),
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final MouseCursor cursor;
  final double scaleDown;
  final double hoverScale;
  final Duration pressDuration;
  final Duration releaseDuration;

  @override
  ConsumerState<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends ConsumerState<AppPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pressDuration,
      reverseDuration: widget.releaseDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!widget.enabled) return;
    _controller.reverse();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!widget.enabled) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final motionEnabled = ref.watch(motionEnabledProvider);

    // If motion is off or widget is disabled, bypass animation transforms
    if (!motionEnabled || !widget.enabled) {
      Widget content = widget.child;
      if (widget.onTap != null || widget.onLongPress != null) {
        content = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? widget.onTap : null,
          onLongPress: widget.enabled ? widget.onLongPress : null,
          child: content,
        );
      }
      return content;
    }

    Widget content = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        double scale = _scaleAnimation.value;
        if (_isHovered && _controller.status == AnimationStatus.dismissed) {
          scale = widget.hoverScale;
        }
        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: content,
      );
    }

    content = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: content,
    );

    return MouseRegion(
      cursor: widget.enabled ? widget.cursor : SystemMouseCursors.basic,
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      child: content,
    );
  }
}
