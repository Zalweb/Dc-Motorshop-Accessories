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
  static Widget buildTabSwitcher({
    required int currentIndex,
    required Widget child,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.015, 0),
          end: Offset.zero,
        ).animate(animation);

        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(animation);

        return SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: fade,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(currentIndex),
        child: child,
      ),
    );
  }
}
