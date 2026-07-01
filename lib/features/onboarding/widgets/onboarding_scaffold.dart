import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// Shared layout for onboarding steps: a progress bar, a step label,
/// title/subtitle, scrollable body, and a Back / primary action footer pinned
/// to the bottom.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.stepLabel,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.backLabel = 'Back',
    this.onBack,
    this.isPrimaryLoading = false,
    this.totalSteps = 3,
  });

  final int step;
  final String stepLabel;
  final String title;
  final String subtitle;
  final Widget child;
  final String primaryLabel;
  final String backLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final bool isPrimaryLoading;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            _ProgressBar(step: step, total: totalSteps),
            const SizedBox(height: 16),
            Text('Step $step of $totalSteps · $stepLabel',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.headingLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.bodySmall),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: _Footer(
            primaryLabel: primaryLabel,
            backLabel: backLabel,
            onPrimary: onPrimary,
            onBack: onBack,
            isPrimaryLoading: isPrimaryLoading,
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: List.generate(total, (i) {
        final filled = i < step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 8),
            height: 6,
            decoration: BoxDecoration(
              color: filled ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.primaryLabel,
    required this.onPrimary,
    required this.backLabel,
    required this.onBack,
    required this.isPrimaryLoading,
  });

  final String primaryLabel;
  final String backLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final bool isPrimaryLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (onBack != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                foregroundColor: theme.colorScheme.onSurface,
              ),
              child: Text(backLabel),
            ),
          ),
        if (onBack != null) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: isPrimaryLoading ? null : onPrimary,
            child: isPrimaryLoading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Text(primaryLabel),
          ),
        ),
      ],
    );
  }
}
