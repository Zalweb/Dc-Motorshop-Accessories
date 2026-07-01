import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/business_settings.dart';
import '../../shared/widgets/glass_container.dart';
import '../dashboard/business_calendar_screen.dart';
import '../expenses/expenses_screen.dart';
import '../more/general_settings_screen.dart';
import '../products/add_product_screen.dart';

/// Where a checklist item's action takes the user to complete it.
enum _Target { branding, addProduct, expenses, calendar }

class _ChecklistItem {
  const _ChecklistItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.target,
  });

  final String id;
  final String title;
  final String subtitle;
  final String actionLabel;
  final _Target target;
}

const _essentials = <_ChecklistItem>[
  _ChecklistItem(
    id: 'add_logo',
    title: 'Add your business logo',
    subtitle: 'Make your receipts and dashboard feel like yours.',
    actionLabel: 'Add logo',
    target: _Target.branding,
  ),
  _ChecklistItem(
    id: 'add_address',
    title: 'Add address and phone number',
    subtitle: 'Shown on receipts so customers can reach you.',
    actionLabel: 'Add details',
    target: _Target.branding,
  ),
  _ChecklistItem(
    id: 'add_product',
    title: 'Add your first product',
    subtitle: 'You need at least one product before you can ring up a sale.',
    actionLabel: 'Add product',
    target: _Target.addProduct,
  ),
  _ChecklistItem(
    id: 'setup_workflow',
    title: 'Set up your order workflow',
    subtitle: 'Pending → Processing → Completed, or your own stages.',
    actionLabel: 'Review workflow',
    target: _Target.branding,
  ),
];

const _fineTune = <_ChecklistItem>[
  _ChecklistItem(
    id: 'first_expense',
    title: 'Record your first expense',
    subtitle: 'Track rent, utilities, supplies — anything you spend.',
    actionLabel: 'Add expense',
    target: _Target.expenses,
  ),
  _ChecklistItem(
    id: 'closed_days',
    title: 'Tell us your closed days',
    subtitle: 'Tag Sundays and holidays so your numbers match real life.',
    actionLabel: 'Open calendar',
    target: _Target.calendar,
  ),
];

const _allItems = [..._essentials, ..._fineTune];

/// Snapshot of the live app state the checklist derives completion from.
class _Progress {
  const _Progress({
    required this.settings,
    required this.productCount,
    required this.expenseCount,
    required this.hasClosedDays,
  });

  final BusinessSettings settings;
  final int productCount;
  final int expenseCount;
  final bool hasClosedDays;

  /// Whether [item] is satisfied by the actual data in the app — never a
  /// stored flag.
  bool isDone(_ChecklistItem item) {
    switch (item.id) {
      case 'add_logo':
        return (settings.logoPath ?? '').trim().isNotEmpty;
      case 'add_address':
        return (settings.address ?? '').trim().isNotEmpty &&
            (settings.phone ?? '').trim().isNotEmpty;
      case 'add_product':
        return productCount > 0;
      case 'setup_workflow':
        return settings.workflowStages.isNotEmpty;
      case 'first_expense':
        return expenseCount > 0;
      case 'closed_days':
        return hasClosedDays;
      default:
        return false;
    }
  }
}

class SetupChecklistScreen extends ConsumerStatefulWidget {
  const SetupChecklistScreen({super.key});

  @override
  ConsumerState<SetupChecklistScreen> createState() =>
      _SetupChecklistScreenState();
}

class _SetupChecklistScreenState extends ConsumerState<SetupChecklistScreen> {
  bool _hasClosedDays() {
    return ref.read(calendarClosedDatesProvider).isNotEmpty;
  }

  Future<void> _openTarget(_Target target) async {
    final Widget screen = switch (target) {
      _Target.branding => const GeneralSettingsScreen(),
      _Target.addProduct => const AddProductScreen(),
      _Target.expenses => const ExpensesScreen(),
      _Target.calendar => const BusinessCalendarScreen(),
    };
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    // Closed days live in SharedPreferences (not a stream), so re-read on return.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(businessSettingsStreamProvider).value;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (settings == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          title: const Text('Setup Checklist'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final progress = _Progress(
      settings: settings,
      productCount: ref.watch(productListStreamProvider).value?.length ?? 0,
      expenseCount: ref.watch(expenseListStreamProvider).value?.length ?? 0,
      hasClosedDays: _hasClosedDays(),
    );

    final doneCount = _allItems.where(progress.isDone).length;
    final fraction = doneCount / _allItems.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Setup Checklist'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Hero progress card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary.withValues(alpha: 0.08),
                  theme.colorScheme.surfaceContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doneCount == _allItems.length
                      ? "You're all set up!"
                      : 'Finish setting up\nDC Motorcycle Inventory',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$doneCount of ${_allItems.length} completed',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${(fraction * 100).round()}%',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _SectionLabel('Essentials', 'Required before your first sale'),
          ..._essentials.map((item) => _ChecklistTile(
                item: item,
                done: progress.isDone(item),
                onTap: () => _openTarget(item.target),
              )),
          const SizedBox(height: 20),

          _SectionLabel('Fine-tune', 'Sharpen your profit & inventory metrics'),
          ..._fineTune.map((item) => _ChecklistTile(
                item: item,
                done: progress.isDone(item),
                onTap: () => _openTarget(item.target),
              )),
          const SizedBox(height: 32),

          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('FINISH FOR NOW'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.item,
    required this.done,
    required this.onTap,
  });

  final _ChecklistItem item;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          color: done
              ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surfaceContainer,
          border: Border.all(
            color: done
                ? theme.colorScheme.primary.withValues(alpha: 0.6)
                : theme.colorScheme.outlineVariant,
            width: done ? 1.5 : 1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked_rounded,
                color: done
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: done
                            ? theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6)
                            : theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    if (!done) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.actionLabel,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                size: 12, color: primary),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
