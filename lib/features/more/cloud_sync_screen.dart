import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/primary_button.dart';

/// Cloud backup & sync screen — lets the user manually trigger a Supabase
/// sync, restore from cloud, and see the current sync status.
///
/// Accessible from the More tab → Cloud Backup & Sync.
class CloudSyncScreen extends ConsumerStatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  ConsumerState<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends ConsumerState<CloudSyncScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLinking = false;
  
  bool _isSyncing = false;
  bool _isRestoring = false;
  String? _lastMessage;
  bool _lastSuccess = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isSignedIn => SupabaseService.hasSession;
  String? get _userEmail => SupabaseService.client.auth.currentUser?.email;

  Future<void> _linkAccount() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _lastSuccess = false;
        _lastMessage = 'Please enter your password to link your account.';
      });
      return;
    }

    setState(() {
      _isLinking = true;
      _lastMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.linkAccountToCloud(password: password);
      
      setState(() {
        _lastSuccess = true;
        _lastMessage = 'Account successfully linked to cloud! You can now sync your data.';
        _passwordController.clear();
      });
    } catch (e) {
      setState(() {
        _lastSuccess = false;
        _lastMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLinking = false);
      }
    }
  }

  Future<void> _syncNow() async {
    setState(() {
      _isSyncing = true;
      _lastMessage = null;
    });
    try {
      final synced =
          await ref.read(supabaseSyncServiceProvider).syncNow();
      setState(() {
        _lastSuccess = synced;
        _lastMessage = synced
            ? 'Sync complete! Your data is up to date in the cloud.'
            : 'Not signed in — please log in to sync.';
      });
    } catch (e) {
      setState(() {
        _lastSuccess = false;
        _lastMessage = 'Sync failed: ${e.toString()}';
      });
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _restoreFromCloud() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.cloud_download_rounded,
                  color: AppColors.danger, size: 28),
              const SizedBox(width: 8),
              Text('Restore from Cloud?',
                  style:
                      AppTextStyles.headingMedium.copyWith(fontSize: 18)),
            ],
          ),
          content: const Text(
            'This will download all data from the cloud and overwrite any '
            'local changes that have not been pushed yet. Continue?',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel',
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isRestoring = true;
      _lastMessage = null;
    });
    try {
      final ok =
          await ref.read(supabaseSyncServiceProvider).restoreFromCloud();
      setState(() {
        _lastSuccess = ok;
        _lastMessage = ok
            ? 'Restore complete! All cloud data has been downloaded.'
            : 'Not signed in — please log in to restore.';
      });
    } catch (e) {
      setState(() {
        _lastSuccess = false;
        _lastMessage = 'Restore failed: ${e.toString()}';
      });
    } finally {
      setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backup & Sync'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Status card ──────────────────────────────────────────────
            GlassContainer(
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _isSignedIn
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: _isSignedIn ? Colors.green : AppColors.expense,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSignedIn ? 'Connected to Supabase' : 'Not signed in',
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSignedIn
                              ? 'Signed in as $_userEmail\nData syncs automatically when online.'
                              : 'Log in to enable cloud sync and backup.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Result banner ────────────────────────────────────────────
            if (_lastMessage != null) ...[
              GlassContainer(
                borderRadius: BorderRadius.circular(12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _lastSuccess
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: _lastSuccess ? Colors.green : AppColors.danger,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _lastMessage!,
                        style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Link Account to Cloud ────────────────────────────────────
            if (!_isSignedIn) ...[
              Text(
                'LINK ACCOUNT TO CLOUD',
                style: AppTextStyles.labelCaps
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Cloud Sync',
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your password to link this offline account to Supabase. '
                      'Once linked, your data will sync across devices automatically.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        suffixIcon: TextButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(_obscurePassword ? 'Show' : 'Hide'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Link Account',
                      isLoading: _isLinking,
                      onPressed: _linkAccount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // ── Sync Now ─────────────────────────────────────────────────
            Text(
              'SYNC TO CLOUD',
              style: AppTextStyles.labelCaps
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload changes to Supabase',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pushes all local changes (products, sales, expenses, '
                    'categories) to the cloud and pulls any remote updates. '
                    'This happens automatically when you go online.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: (_isSyncing || !_isSignedIn) ? null : _syncNow,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync_rounded),
                    label:
                        Text(_isSyncing ? 'Syncing…' : 'Sync Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Restore from Cloud ────────────────────────────────────────
            Text(
              'RESTORE FROM CLOUD',
              style: AppTextStyles.labelCaps
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download all data from Supabase',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Downloads your complete shop data from the cloud into '
                    'this device. Useful after reinstalling the app or '
                    'switching to a new phone.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Warning: This will overwrite any local data that has not '
                    'been pushed to the cloud.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed:
                        (_isRestoring || !_isSignedIn) ? null : _restoreFromCloud,
                    icon: _isRestoring
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_download_rounded),
                    label: Text(
                        _isRestoring ? 'Restoring…' : 'Restore from Cloud'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ── Info footer ───────────────────────────────────────────────
            GlassContainer(
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Data is encrypted in transit (HTTPS) and stored in a '
                      'private Supabase PostgreSQL database. Row-Level Security '
                      'ensures only your account can access your shop data.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
