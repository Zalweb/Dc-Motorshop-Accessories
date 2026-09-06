import 'package:flutter/material.dart';

/// Controller for imperatively triggering the floating pop-up animation.
class FloatingAddPopUpController {
  VoidCallback? _trigger;

  void register(VoidCallback callback) {
    _trigger = callback;
  }

  void unregister() {
    _trigger = null;
  }

  /// Triggers a floating +1 bubble toward the top.
  void trigger() {
    _trigger?.call();
  }
}

/// A wrapper widget that animates a vibrant floating badge (e.g. "+1")
/// moving upward toward the top of the card whenever triggered.
class FloatingAddPopUp extends StatefulWidget {
  const FloatingAddPopUp({
    super.key,
    required this.controller,
    required this.child,
    this.label = '+1',
    this.badgeColor,
  });

  final FloatingAddPopUpController controller;
  final Widget child;
  final String label;
  final Color? badgeColor;

  @override
  State<FloatingAddPopUp> createState() => _FloatingAddPopUpState();
}

class _FloatingAddPopUpState extends State<FloatingAddPopUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _slideAnim = Tween<double>(begin: 0.0, end: -85.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
      ),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 65,
      ),
    ]).animate(_anim);

    widget.controller.register(_onTrigger);
  }

  @override
  void didUpdateWidget(covariant FloatingAddPopUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.unregister();
      widget.controller.register(_onTrigger);
    }
  }

  @override
  void dispose() {
    widget.controller.unregister();
    _anim.dispose();
    super.dispose();
  }

  void _onTrigger() {
    _anim.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.badgeColor ?? theme.colorScheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                if (_anim.value == 0.0 || _anim.value == 1.0) {
                  return const SizedBox.shrink();
                }

                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: Opacity(
                        opacity: _fadeAnim.value.clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.45),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
