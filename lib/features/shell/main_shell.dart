import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/sync_status_banner.dart';

/// Hosts the five primary tabs behind a shared bottom navigation bar.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      body: Stack(
        children: [
          // The actual tab content.
          navigationShell,

          // Online / offline banner — slides in from top when connectivity changes.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConnectivityBanner(),
          ),

          // Sync Status banner — slides down to show auto-sync progress.
          const Positioned(
            top: 40, // Below the connectivity banner if it's showing, or just safe area
            left: 0,
            right: 0,
            child: SyncStatusBanner(),
          ),
        ],
      ),
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
