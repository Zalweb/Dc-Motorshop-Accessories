import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../theme/app_text_styles.dart';
import '../app_update_info.dart';
import 'update_dialog.dart';

/// Top notification banner that smoothly slides in when a software update is available.
class UpdateNotificationBanner extends ConsumerStatefulWidget {
  const UpdateNotificationBanner({super.key});

  @override
  ConsumerState<UpdateNotificationBanner> createState() =>
      _UpdateNotificationBannerState();
}

class _UpdateNotificationBannerState
    extends ConsumerState<UpdateNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss(AppUpdateInfo info) {
    _controller.reverse();
    ref.read(appUpdateControllerProvider.notifier).dismiss(info.latestVersion);
  }

  @override
  Widget build(BuildContext context) {
    final updateAsync = ref.watch(appUpdateControllerProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return updateAsync.when(
      data: (info) {
        final shouldShow = info != null &&
            info.hasUpdate &&
            (!info.isDismissed || info.isMandatory);

        if (!shouldShow) {
          if (_controller.isCompleted || _controller.isAnimating) {
            _controller.reverse();
          }
          return const SizedBox.shrink();
        }

        if (!_controller.isCompleted && !_controller.isAnimating) {
          _controller.forward();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.topCenter,
              child: SlideTransition(
                position: _slide,
                child: Material(
                  elevation: 6,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.rocket_launch_rounded,
                            color: primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Update available: v${info.latestVersion}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => UpdateDialog.show(
                            context,
                            info: info,
                          ),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Update',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (!info.isMandatory) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            visualDensity: VisualDensity.compact,
                            color: theme.colorScheme.onSurfaceVariant,
                            tooltip: 'Dismiss update notice',
                            onPressed: () => _dismiss(info),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
