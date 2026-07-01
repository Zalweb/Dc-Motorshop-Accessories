import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/motion_controller.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../shared/widgets/brand_mark.dart';
import '../../shared/widgets/glass_container.dart';
import '../auth/auth_controller.dart';
import '../customers/customers_screen.dart';
import '../expenses/expenses_screen.dart';
import '../dashboard/business_calendar_screen.dart';
import '../dashboard/financial_calendar_screen.dart';
import '../dashboard/reports_screen.dart';
import 'general_settings_screen.dart';
import 'import_export_screen.dart';
import 'inventory_settings_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final settings = ref.watch(businessSettingsStreamProvider).value;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final themeMode = ref.watch(themeModeProvider);
    final motionEnabled = ref.watch(motionEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Redesigned Profile Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withValues(alpha: 0.12), theme.colorScheme.surfaceContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                settings?.logoPath != null && settings!.logoPath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: settings.logoPath!.startsWith('http')
                            ? Image.network(
                                settings.logoPath!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(settings.logoPath!),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const BrandMark(size: 56),
                              ),
                      )
                    : const BrandMark(size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? user?.username ?? 'User',
                        style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
                      ),
                      if (user != null) ...[
                        const SizedBox(height: 4),
                        Text('@${user.username}', style: AppTextStyles.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          
          Text(
            'ACCOUNT',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _InfoCard(rows: [
            ('Email', user?.email ?? '—'),
            ('Phone', user?.phone ?? '—'),
          ]),
          const SizedBox(height: 28),
          
          Text(
            'BUSINESS',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _BusinessCard(
            name: settings?.businessName ?? 'DC Motorshop & Accessories',
            address: settings?.address,
            phone: settings?.phone,
            email: settings?.email,
            qrLink: settings?.receiptQrLink,
            logoPath: settings?.logoPath,
          ),
          const SizedBox(height: 28),

          Text(
            'BUSINESS SETTINGS',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.settings_outlined, color: primary),
                  title: Text('General', style: AppTextStyles.body),
                  subtitle: Text(
                    'Manage business details and settings',
                    style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const GeneralSettingsScreen()),
                  ),
                ),
                Divider(color: theme.colorScheme.outlineVariant, height: 1),
                ListTile(
                  leading: Icon(Icons.inventory_2_outlined, color: primary),
                  title: Text('Inventory', style: AppTextStyles.body),
                  subtitle: Text(
                    'Configure inventory settings',
                    style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const InventorySettingsScreen()),
                  ),
                ),
                Divider(color: theme.colorScheme.outlineVariant, height: 1),
                ListTile(
                  leading: Icon(Icons.calendar_today_outlined, color: primary),
                  title: Text('Business Calendar', style: AppTextStyles.body),
                  subtitle: Text(
                    'Tag closed days so daily expenses & Sales target stays accurate',
                    style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const BusinessCalendarScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'INSIGHT',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.calendar_month_outlined, color: primary),
                  title: Text('Financial Calendar', style: AppTextStyles.body),
                  subtitle: Text(
                    'Daily revenue & profit heatmap, month by month',
                    style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const FinancialCalendarScreen()),
                  ),
                ),
                Divider(color: theme.colorScheme.outlineVariant, height: 1),
                ListTile(
                  leading: Icon(Icons.analytics_outlined, color: primary),
                  title: Text('Reports', style: AppTextStyles.body),
                  subtitle: Text(
                    'Sales trends, top products & day-of-week patterns',
                    style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'FINANCE',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.payments_outlined, color: primary),
                  title: Text('Expenses', style: AppTextStyles.body),
                  subtitle: Text(
                    'Variable & fixed operating costs',
                    style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                  ),
                ),
                Divider(color: theme.colorScheme.outlineVariant, height: 1),
                ListTile(
                  leading: Icon(Icons.people_alt_outlined, color: primary),
                  title: Text('Customers', style: AppTextStyles.body),
                  subtitle: Text(
                    'View customer list & balances',
                    style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const CustomersScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'APPEARANCE',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: primary),
                      const SizedBox(width: 12),
                      Text('Theme', style: AppTextStyles.body),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ThemeModeSelector(
                    mode: themeMode,
                    onChanged: (m) =>
                        ref.read(themeModeProvider.notifier).set(m),
                  ),
                  const SizedBox(height: 8),
                  Divider(color: theme.colorScheme.outlineVariant, height: 24),
                  Row(
                    children: [
                      Icon(Icons.animation_outlined, color: primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Motion', style: AppTextStyles.body),
                            Text(
                              'Animations across the app',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: motionEnabled,
                        onChanged: (v) =>
                            ref.read(motionEnabledProvider.notifier).set(v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'ACTIONS',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          
          // Grouped settings list tiles inside a single card surface
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.checklist_rounded, color: primary),
                  title: Text('Setup checklist', style: AppTextStyles.body),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => context.push(RoutePaths.setupChecklist),
                ),
                Divider(color: theme.colorScheme.outlineVariant, height: 1),
                 ListTile(
                  leading: Icon(Icons.swap_horizontal_circle_outlined, color: primary),
                  title: Text('Import/Export Data', style: AppTextStyles.body),
                  subtitle: Text('Transfer data securely to another phone', style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const ImportExportScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'CLOUD',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.cloud_upload_rounded, color: primary),
                  title: Text('Sync now', style: AppTextStyles.body),
                  subtitle: Text(
                    'Back up local changes and pull updates',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => _runCloudAction(
                    context,
                    busy: 'Syncing…',
                    done: 'Sync complete',
                    signedOut: 'Sign in online to sync',
                    action: () => ref.read(supabaseSyncServiceProvider).syncNow(),
                  ),
                ),
                Divider(color: theme.colorScheme.outlineVariant, height: 1),
                ListTile(
                  leading: Icon(Icons.cloud_download_rounded, color: primary),
                  title: Text('Restore from cloud', style: AppTextStyles.body),
                  subtitle: Text(
                    'Reload this shop\'s data from the server',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => _runCloudAction(
                    context,
                    busy: 'Restoring…',
                    done: 'Restore complete',
                    signedOut: 'Sign in online to restore',
                    action: () => ref.read(supabaseSyncServiceProvider).restoreFromCloud(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'ADVANCE',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            child: Theme(
              // Strip ExpansionTile's default dividers so it blends with the card.
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Icon(Icons.admin_panel_settings_outlined, color: primary),
                title: Text('Advance account options', style: AppTextStyles.body),
                subtitle: Text(
                  'Reset or delete your local data',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded, color: AppColors.danger),
                    title: const Text(
                      'Reset Local Data',
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Clear products, sales & expenses on this device',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    onTap: () => _confirmResetLocalData(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined, color: AppColors.danger),
                    title: const Text(
                      'Delete account',
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Erase all local data and sign out',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    onTap: () => _confirmDeleteAccount(context, ref),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),

          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            label: const Text(
              'LOG OUT',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              side: const BorderSide(color: AppColors.danger, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 32),

          const _DeveloperFooter(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Segmented System / Light / Dark picker for the Appearance section.
class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = [
    (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
    (ThemeMode.light, 'Light', Icons.light_mode_outlined),
    (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      children: [
        for (final (value, label, icon) in _options)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: value == ThemeMode.dark ? 0 : 10),
              child: InkWell(
                onTap: () => onChanged(value),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: mode == value
                        ? primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: mode == value
                          ? primary
                          : theme.colorScheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 24,
                        color: mode == value
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: mode == value
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shows a busy snackbar, runs a cloud action, then reports the outcome. The action
/// returns false when signed out (offline-only session).
Future<void> _runCloudAction(
  BuildContext context, {
  required String busy,
  required String done,
  required String signedOut,
  required Future<bool> Function() action,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(SnackBar(content: Text(busy)));
  try {
    final ok = await action();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(ok ? done : signedOut)));
  } catch (error) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

/// Confirms, then clears local business data (catalog, sales, expenses).
Future<void> _confirmResetLocalData(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reset local data?'),
      content: const Text(
        'This clears all products, sales and expenses stored on this device. '
        'Your account and business settings are kept. This cannot be undone.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Reset'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await ref.read(maintenanceRepositoryProvider).resetLocalData();
  messenger.showSnackBar(const SnackBar(content: Text('Local data reset')));
}

/// Confirms, then erases every local collection and signs the user out.
Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete account?'),
      content: const Text(
        'This erases all local data on this device and signs you out. '
        'This cannot be undone.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await ref.read(maintenanceRepositoryProvider).deleteAllLocal();
  await ref.read(authControllerProvider.notifier).logout();
}

/// Formal app/developer credit shown at the bottom of the More page.
class _DeveloperFooter extends StatelessWidget {
  const _DeveloperFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Divider(color: theme.colorScheme.outlineVariant, height: 1),
        const SizedBox(height: 20),
        Text(
          'DC Motorcycle Inventory',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Designed & developed by',
          style: AppTextStyles.bodySmall.copyWith(color: muted, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          'Frienzal S. Labisig',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 15, color: muted),
            const SizedBox(width: 6),
            SelectableText(
              'frienzalsumalpong@gmail.com',
              style: AppTextStyles.bodySmall.copyWith(color: muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '© 2026 Frienzal S. Labisig · All rights reserved',
          style: AppTextStyles.bodySmall.copyWith(color: muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row.$1,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(row.$2, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.qrLink,
    this.logoPath,
  });

  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? qrLink;
  final String? logoPath;

  Widget _buildDefaultIcon(Color primary) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.two_wheeler_rounded, color: primary, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final details = <(IconData, String)>[
      if (address != null && address!.isNotEmpty) (Icons.location_on_outlined, address!),
      if (phone != null && phone!.isNotEmpty) (Icons.phone_outlined, phone!),
      if (email != null && email!.isNotEmpty) (Icons.email_outlined, email!),
      if (qrLink != null && qrLink!.isNotEmpty) (Icons.qr_code_rounded, qrLink!),
    ];

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              logoPath != null && logoPath!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: logoPath!.startsWith('http')
                          ? Image.network(
                              logoPath!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(logoPath!),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildDefaultIcon(primary),
                            ),
                    )
                  : _buildDefaultIcon(primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (details.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Add your business details in General settings.',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Divider(color: theme.colorScheme.outlineVariant, height: 1),
            const SizedBox(height: 14),
            for (var i = 0; i < details.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(details[i].$1, size: 18, color: primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      details[i].$2,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

