import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/brand_mark.dart';

/// Branded loading screen (reference 6.jpg). Routing is handled by the auth
/// guard in the router; this screen is purely visual while the session loads.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          // Background soft radial gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    primary.withOpacity(0.12),
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  const Center(child: BrandMark(size: 110)),
                  const SizedBox(height: 32),
                  Text(
                    AppStrings.businessName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge.copyWith(letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.preparingDashboard,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(letterSpacing: 0.2),
                  ),
                  const Spacer(flex: 2),
                  const Center(child: _Dots()),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1.0),
            duration: Duration(milliseconds: 400 + (i * 200)),
            curve: Curves.easeInOut,
            builder: (context, val, child) {
              return CircleAvatar(
                radius: 4.5,
                backgroundColor: primary.withOpacity(i == 0 ? 1.0 : 0.4),
              );
            },
          ),
        ),
      ),
    );
  }
}

