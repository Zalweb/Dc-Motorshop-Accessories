import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/brand_mark.dart';

/// Branded loading screen (reference 6.jpg). Routing is handled by the auth
/// guard in the router; this screen is purely visual while the session loads.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(businessSettingsStreamProvider).value;
    final businessName = (settings?.businessName != null && settings!.businessName.trim().isNotEmpty)
        ? settings.businessName.trim()
        : AppStrings.businessName;
    final logoPath = settings?.logoPath?.trim();

    return Scaffold(
      body: Stack(
        children: [
          // Solid background color (handled by Scaffold)
          Positioned.fill(
            child: Container(
              color: theme.scaffoldBackgroundColor,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  Center(
                    child: (logoPath != null && logoPath.isNotEmpty)
                        ? AppImage(
                            imageUrl: logoPath,
                            imagePath: logoPath,
                            width: 110,
                            height: 110,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(24),
                          )
                        : const BrandMark(size: 110),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    businessName,
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
                backgroundColor: primary.withValues(alpha: i == 0 ? 1.0 : 0.4),
              );
            },
          ),
        ),
      ),
    );
  }
}

