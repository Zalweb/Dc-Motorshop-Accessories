import 'package:flutter/material.dart';

/// Page transition used app-wide when Motion is on. The incoming page slides in
/// from the right while fading; the page it covers drifts slightly left and
/// dims, giving a layered, premium feel on every push/pop. Applied via the
/// theme, so it drives both go_router `builder:` routes and `Navigator.push`.
class MotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const MotionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final entering = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final exiting = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final slideIn = Tween<Offset>(
      begin: const Offset(0.12, 0),
      end: Offset.zero,
    ).animate(entering);

    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.06, 0),
    ).animate(exiting);
    final dimOut = Tween<double>(begin: 1, end: 0.85).animate(exiting);

    return SlideTransition(
      position: slideOut,
      child: FadeTransition(
        opacity: dimOut,
        child: SlideTransition(
          position: slideIn,
          child: FadeTransition(opacity: entering, child: child),
        ),
      ),
    );
  }
}

/// Shows the destination instantly (no transition), used app-wide when the user
/// turns Motion off.
class NoMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoMotionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

PageTransitionsTheme _allPlatforms(PageTransitionsBuilder builder) =>
    PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values) platform: builder,
      },
    );

final kMotionPageTransitionsTheme = _allPlatforms(const MotionPageTransitionsBuilder());
final kNoMotionPageTransitionsTheme = _allPlatforms(const NoMotionPageTransitionsBuilder());
