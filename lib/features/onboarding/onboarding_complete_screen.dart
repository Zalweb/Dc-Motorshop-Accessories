import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/primary_button.dart';
import 'onboarding_controller.dart';

class OnboardingCompleteScreen extends ConsumerStatefulWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  ConsumerState<OnboardingCompleteScreen> createState() =>
      _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState
    extends ConsumerState<OnboardingCompleteScreen> {
  bool _saving = false;

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref.read(onboardingControllerProvider.notifier).finish();
    if (!mounted) return;
    context.go(RoutePaths.dashboard);
  }

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
                    primary.withOpacity(0.08),
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  
                  // Concentric success rings
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  Text(
                    "You're all set!",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge.copyWith(letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'DC Motorcycle Inventory is ready for your first sale.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  PrimaryButton(
                    label: 'GO TO DASHBOARD',
                    isLoading: _saving,
                    onPressed: _finish,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You can update settings anytime',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

