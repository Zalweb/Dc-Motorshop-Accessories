import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/glass_container.dart';
import 'onboarding_controller.dart';
import 'widgets/onboarding_scaffold.dart';

/// Step 2 — review the product categories. Add or remove as needed.
class OnboardingReviewSetupScreen extends ConsumerStatefulWidget {
  const OnboardingReviewSetupScreen({super.key});

  @override
  ConsumerState<OnboardingReviewSetupScreen> createState() =>
      _OnboardingReviewSetupScreenState();
}

class _OnboardingReviewSetupScreenState
    extends ConsumerState<OnboardingReviewSetupScreen> {
  final _categoryInput = TextEditingController();

  @override
  void dispose() {
    _categoryInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final theme = Theme.of(context);

    return OnboardingScaffold(
      step: 2,
      stepLabel: 'Categories',
      title: 'Review your categories',
      subtitle: 'Smart defaults for your shop. Add or remove anything.',
      primaryLabel: 'Looks good',
      onBack: () => context.pop(),
      onPrimary: () => context.push(RoutePaths.onboardingStep3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(categoryCount: draft.categories.length),
          const SizedBox(height: 28),
          
          Text(
            'ACTIVE CATEGORIES',
            style: AppTextStyles.labelCaps,
          ),
          const SizedBox(height: 14),
          
          // Wrapped Chip grid instead of stacked full-width rows
          if (draft.categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No categories added yet. Add one below.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: draft.categories.map(
                (c) => Chip(
                  label: Text(c),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => controller.removeCategory(c),
                  deleteIconColor: theme.colorScheme.onSurfaceVariant,
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  labelStyle: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                ),
              ).toList(),
            ),
            
          const SizedBox(height: 32),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 24),
          
          Text(
            'CREATE CUSTOM CATEGORY',
            style: AppTextStyles.labelCaps,
          ),
          const SizedBox(height: 12),
          
          _AddRow(
            controller: _categoryInput,
            hint: 'e.g. Engine Oil, Exhausts...',
            onAdd: () {
              if (_categoryInput.text.trim().isNotEmpty) {
                controller.addCategory(_categoryInput.text.trim());
                _categoryInput.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.categoryCount});

  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.two_wheeler, color: primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Motorcycle Shop',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  '$categoryCount categories active',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({
    required this.controller,
    required this.hint,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 56,
          child: FilledButton.tonal(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: primary.withOpacity(0.15),
              foregroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(70, 56),
            ),
            child: const Text('Add'),
          ),
        ),
      ],
    );
  }
}

