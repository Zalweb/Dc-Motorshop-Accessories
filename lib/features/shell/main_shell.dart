import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/page_transitions.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_side_nav.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/sync_status_banner.dart';

/// Hosts the primary tabs behind a responsive navigation shell:
/// SideNav on wide screens (desktop/tablet >= 800px) and BottomNav on mobile.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    final content = Stack(
      children: [
        // The actual tab content with smooth motion & cross-fade
        AppPageTransitions.buildTabSwitcher(
          currentIndex: navigationShell.currentIndex,
          child: navigationShell,
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
      ],
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            AppSideNav(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: false,
      body: content,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
