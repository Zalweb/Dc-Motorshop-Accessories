import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/page_transitions.dart';
import '../../core/update/widgets/update_banner.dart';
import '../../core/update/widgets/update_dialog.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_side_nav.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/sync_status_banner.dart';

/// Hosts the primary tabs behind a responsive navigation shell:
/// SideNav on wide screens (desktop/tablet >= 800px) and BottomNav on mobile.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _checkedMandatory = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(appUpdateControllerProvider, (_, next) {
      if (kIsWeb) return;
      final info = next.value;
      if (info != null && info.hasUpdate && info.isMandatory && !_checkedMandatory) {
        _checkedMandatory = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            UpdateDialog.show(context, info: info, isDismissible: false);
          }
        });
      }
    });

    final isWide = MediaQuery.sizeOf(context).width >= 800;

    final content = Stack(
      children: [
        // The actual tab content with smooth motion & cross-fade
        AppPageTransitions.buildTabSwitcher(
          currentIndex: widget.navigationShell.currentIndex,
          child: widget.navigationShell,
        ),

        // Online / offline banner — slides in from top when connectivity changes.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ConnectivityBanner(),
        ),

        // Sync Status banner — slides down to show auto-sync progress.
        const Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: SyncStatusBanner(),
        ),

        // Software update banner — slides down when a newer release is published.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: UpdateNotificationBanner(),
        ),
      ],
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            AppSideNav(
              currentIndex: widget.navigationShell.currentIndex,
              onTap: (index) => widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              ),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: false,
      body: content,
      bottomNavigationBar: AppBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
      ),
    );
  }
}
