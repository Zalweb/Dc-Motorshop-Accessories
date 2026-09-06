import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/glass_container.dart';
import '../../providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../app_update_info.dart';
import '../update_action.dart';

/// Modal dialog presenting software release details and update options.
///
/// Assures user data safety: local database records (Isar) and SharedPreferences
/// are never touched or cleared during an update.
class UpdateDialog extends ConsumerStatefulWidget {
  const UpdateDialog({
    super.key,
    required this.info,
    this.isDismissible = true,
  });

  final AppUpdateInfo info;
  final bool isDismissible;

  /// Convenience helper to display the update dialog.
  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo info,
    bool isDismissible = true,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: isDismissible && !info.isMandatory,
      builder: (ctx) => UpdateDialog(
        info: info,
        isDismissible: isDismissible && !info.isMandatory,
      ),
    );
  }

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  bool _isLaunching = false;

  Future<void> _handleUpdate() async {
    setState(() => _isLaunching = true);
    try {
      final success = await triggerPlatformUpdate(widget.info);
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not automatically launch update URL.'),
          ),
        );
      } else if (!kIsWeb) {
        // On native platforms, close dialog after triggering download/browser
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  Future<void> _handleLater() async {
    await ref
        .read(appUpdateControllerProvider.notifier)
        .dismiss(widget.info.latestVersion);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final info = widget.info;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 600;

    final actionLabel = kIsWeb
        ? 'Reload App Now'
        : (info.formattedApkSize != null
            ? 'Download & Install (${info.formattedApkSize})'
            : 'Update Now');

    return PopScope(
      canPop: widget.isDismissible && !info.isMandatory,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isWide ? 40 : 20,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Rocket Icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        color: primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Update Available',
                            style: AppTextStyles.headingMedium.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.releaseName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (info.isMandatory)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'REQUIRED',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // Version Comparison Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Installed: v${info.currentVersion}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: primary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'Latest: v${info.latestVersion}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: primary,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Reassuring Data Safety Guarantee Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.active.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.active.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.active,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Safe In-Place Update',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your local inventory, sales, customer records, and settings remain 100% intact and will not be erased.',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Release Notes Header
                Text(
                  "WHAT'S NEW",
                  style: AppTextStyles.labelCaps.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),

                // Release Notes Scrollable Body
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        info.cleanReleaseNotes,
                        style: AppTextStyles.bodySmall.copyWith(
                          height: 1.45,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    if (!info.isMandatory) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLaunching ? null : _handleLater,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Later'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: info.isMandatory ? 1 : 2,
                      child: FilledButton.icon(
                        onPressed: _isLaunching ? null : _handleUpdate,
                        icon: _isLaunching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                kIsWeb ? Icons.refresh_rounded : Icons.download_rounded,
                                size: 18,
                              ),
                        label: Text(
                          actionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
