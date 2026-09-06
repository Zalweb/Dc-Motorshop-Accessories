import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Centralized transition builder library for smooth, 60fps / 120Hz page animations.
/// Fully compatible with both Mobile (Android/iOS) and Web.
abstract final class AppPageTransitions {
  static const standardDuration = Duration(milliseconds: 280);
  static const modalDuration = Duration(milliseconds: 320);
  static const fadeDuration = Duration(milliseconds: 240);

  /// Smooth horizontal slide & fade transition (ideal for detail pages & sub-screens).
  static Page<T> slideTransition<T>({
    required GoRouterState state,
    required Widget child,
    Duration duration = standardDuration,
    bool fromLeft = false,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        final slideTween = Tween<Offset>(
          begin: Offset(fromLeft ? -0.15 : 0.15, 0),
          end: Offset.zero,
        );

        final fadeTween = Tween<double>(begin: 0.0, end: 1.0);

        return SlideTransition(
          position: slideTween.animate(curve),
          child: FadeTransition(
            opacity: fadeTween.animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  /// Modern bottom-to-top modal slide transition (ideal for Add Product, Bulk Add, Editors).
  static Page<T> modalSlideTransition<T>({
    required GoRouterState state,
    required Widget child,
    Duration duration = modalDuration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        final slideTween = Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        );

        final fadeTween = Tween<double>(begin: 0.0, end: 1.0);

        return SlideTransition(
          position: slideTween.animate(curve),
          child: FadeTransition(
            opacity: fadeTween.animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  /// Elegant fade-through transition with slight scale (ideal for Auth & Onboarding).
  static Page<T> fadeThroughTransition<T>({
    required GoRouterState state,
    required Widget child,
    Duration duration = fadeDuration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        final scaleTween = Tween<double>(begin: 0.96, end: 1.0);
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0);

        return ScaleTransition(
          scale: scaleTween.animate(curve),
          child: FadeTransition(
            opacity: fadeTween.animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  /// Animated tab switcher for the 5 primary tabs in MainShell.
  /// Uses a high-performance single-subtree transition to preserve 60fps/120Hz
  /// motion without duplicating navigation shell branches.
  static Widget buildTabSwitcher({
    required int currentIndex,
    required Widget child,
  }) {
    return TabTransitionWrapper(
      currentIndex: currentIndex,
      child: child,
    );
  }
}

/// Smooth single-tree tab transition that avoids duplicating StatefulNavigationShell
/// in the widget tree while retaining identical ease-out cubic fade and slide motion.
class TabTransitionWrapper extends StatefulWidget {
  const TabTransitionWrapper({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex;
  final Widget child;

  @override
  State<TabTransitionWrapper> createState() => _TabTransitionWrapperState();
}

class _TabTransitionWrapperState extends State<TabTransitionWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.015, 0),
      end: Offset.zero,
    ).animate(_curve);
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_curve);

    // Initial render is already fully shown
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant TabTransitionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: RepaintBoundary(
          child: widget.child,
        ),
      ),
    );
  }
}

