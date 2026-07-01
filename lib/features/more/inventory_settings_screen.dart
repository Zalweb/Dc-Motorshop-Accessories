import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/business_settings.dart';

/// Settings that govern how sales interact with stock counts. Each toggle
/// persists to the single BusinessSettings record and is read by the sales +
/// reporting logic.
class InventorySettingsScreen extends ConsumerWidget {
  const InventorySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsVal = ref.watch(businessSettingsStreamProvider);

    return settingsVal.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Inventory')),
        body: Center(child: Text('Error loading settings: $error')),
      ),
      data: (settings) {
        if (settings == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Inventory')),
            body: const Center(child: Text('No business settings found.')),
          );
        }
        return _InventorySettingsView(settings: settings);
      },
    );
  }
}

class _InventorySettingsView extends ConsumerWidget {
  const _InventorySettingsView({required this.settings});

  final BusinessSettings settings;

  Future<void> _set(WidgetRef ref, void Function(BusinessSettings) mutate) {
    return ref.read(settingsRepositoryProvider).update(mutate);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            const Text('Inventory'),
            Text(
              settings.businessName,
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SettingsSection(
            icon: Icons.inventory_2_outlined,
            iconColor: const Color(0xFF10B981),
            title: 'Selling & stock',
            subtitle: 'How sales interact with your stock counts.',
            tiles: [
              _ToggleTile(
                title: 'Allow selling when out of stock',
                description:
                    "When on, a sale goes through even if it pushes stock below zero. Useful if you sell items you haven't tracked yet.",
                value: settings.allowSellWhenOutOfStock,
                onChanged: (v) =>
                    _set(ref, (s) => s.allowSellWhenOutOfStock = v),
              ),
              _ToggleTile(
                title: 'Track partial change given',
                leadingIcon: Icons.toll_outlined,
                leadingColor: const Color(0xFFF59E0B),
                description:
                    "If you sometimes give less change than owed, record what's still owed so you can settle later.",
                value: settings.trackPartialChange,
                onChanged: (v) => _set(ref, (s) => s.trackPartialChange = v),
              ),
              _ToggleTile(
                title: 'Include unpaid sales in reports',
                leadingIcon: Icons.bar_chart_rounded,
                leadingColor: theme.colorScheme.onSurface,
                description:
                    "When off, an unpaid utang won't count toward revenue, profit, or cost-of-goods until the customer pays.",
                value: settings.includeUnpaidInReports,
                onChanged: (v) =>
                    _set(ref, (s) => s.includeUnpaidInReports = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tiles,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headingMedium.copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            tiles[i],
          ],
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.leadingIcon,
    this.leadingColor,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? leadingIcon;
  final Color? leadingColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(
                        leadingIcon,
                        size: 18,
                        color: leadingColor ?? theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
