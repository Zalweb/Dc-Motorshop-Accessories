import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium tactile button motion widget.
/// - Clearly Visible Spring Compression: Scales down to 91% on click/tap in 140ms.
/// - Minimum Dwell Time: Guarantees the press animation is visible even on quick mouse clicks.
/// - Elastic Rebound: Bounces back with an authentic spring curve in 240ms.
/// - Web & Desktop Hover Lift: Scales to 104% with pointer cursor.
/// - Zero Interference: Uses Pointer Listener so child button logic works seamlessly.
/// - Cross-Platform Parity: Functions with 100% parity across Mobile and Web.
class TactileButton extends StatefulWidget {
  const TactileButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.91,
    this.hoverScale = 1.04,
    this.duration = const Duration(milliseconds: 140),
    this.reverseDuration = const Duration(milliseconds: 240),
    this.enableHover = true,
    this.cursor = SystemMouseCursors.click,
    this.haptic = true,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final double hoverScale;
  final Duration duration;
  final Duration reverseDuration;
  final bool enableHover;
  final MouseCursor cursor;
  final bool haptic;
  final bool enabled;

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;
  DateTime? _pressedAt;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
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
    _isPressed = true;
    _pressedAt = DateTime.now();
    _controller.forward();
    if (widget.haptic && !kIsWeb) {
      HapticFeedback.lightImpact();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!widget.enabled) return;
    _isPressed = false;

    // Ensure the compression is clearly visible (minimum 80ms dwell) before spring-rebound
    final elapsed = _pressedAt == null
        ? 80
        : DateTime.now().difference(_pressedAt!).inMilliseconds;
    final remaining = 80 - elapsed;

    if (remaining > 0) {
      Future.delayed(Duration(milliseconds: remaining), () {
        if (mounted && !_isPressed) {
          _controller.reverse();
        }
      });
    } else {
      _controller.reverse();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!widget.enabled) return;
    _isPressed = false;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    Widget content = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        double scale = _scaleAnimation.value;
        if (_isHovered && _controller.status == AnimationStatus.dismissed && widget.enableHover) {
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

    // If a custom onTap callback is given, handle it via GestureDetector
    if (widget.onTap != null || widget.onLongPress != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: content,
      );
    }

    // Pointer listener tracks down/up physical motion without absorbing child button events
    content = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: content,
    );

    // MouseRegion for Web / Desktop hover and cursor pointer
    return MouseRegion(
      cursor: widget.enabled ? widget.cursor : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.enableHover && mounted) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (widget.enableHover && mounted) {
          setState(() => _isHovered = false);
        }
      },
      child: content,
    );
  }
}
