import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/glass_container.dart';
import 'widgets/onboarding_scaffold.dart';

/// Optional step. No backend, so invites are not sent — this collects intent
/// and can be skipped. Staff management lands in a later iteration.
class OnboardingInviteStaffScreen extends StatelessWidget {
  const OnboardingInviteStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return OnboardingScaffold(
      step: 3,
      stepLabel: 'Team',
      title: 'Invite your team',
      subtitle: 'Optional — you can add staff anytime from settings.',
      primaryLabel: 'Finish',
      onBack: () => context.pop(),
      onPrimary: () => context.push(RoutePaths.onboardingComplete),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                Icon(Icons.group_add, color: primary, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Running solo for now? Skip this — your account already '
                    'has full access.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => context.push(RoutePaths.onboardingComplete),
              child: const Text('Skip for now'),
            ),
          ),
        ],
      ),
    );
  }
}
