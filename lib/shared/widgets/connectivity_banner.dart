import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/connectivity_provider.dart';
import '../../core/sync/sync_state_provider.dart';

/// A slim animated banner that slides in from the top whenever the device goes
/// offline and slides back out (briefly showing a green "Back Online" state)
/// when connectivity is restored.
///
/// Drop it anywhere above the main content — currently placed inside
/// [MainShell] so it persists across all bottom-nav tabs.
class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  // null = first frame (no banner yet)
  bool? _wasOnline;

  // Show the "Back Online" green flash for 2 seconds then hide.
  bool _showingOnlineFlash = false;

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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChange(bool isOnline) {
    if (_wasOnline == null) {
      // On first emission: only show banner if already offline.
      _wasOnline = isOnline;
      if (!isOnline) _controller.forward();
      return;
    }

    final wasOnline = _wasOnline!;
    _wasOnline = isOnline;

    if (!isOnline && wasOnline) {
      // Just went offline → slide banner in.
      setState(() => _showingOnlineFlash = false);
      _controller.forward();
    } else if (isOnline && !wasOnline) {
      // Just came back online → flash green, stay on screen until sync finishes.
      setState(() => _showingOnlineFlash = true);
      // Wait for syncStateProvider to report success/error to hide.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to connectivity changes and react.
    ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (_, next) {
      next.whenData(_handleChange);
    });

    // Listen to sync state to hide the "Back online" flash when sync completes.
    ref.listen<SyncState>(syncStateProvider, (_, next) {
      if (_showingOnlineFlash && 
          (next == SyncState.success || 
           next == SyncState.error || 
           next == SyncState.conflict || 
           next == SyncState.idle)) {
        _controller.reverse();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => _showingOnlineFlash = false);
          }
        });
      }
    });

    return SlideTransition(
      position: _slide,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showingOnlineFlash
            ? _BannerTile(
                key: const ValueKey('online'),
                color: const Color(0xFF22C55E),    // green-500
                icon: Icons.wifi_rounded,
                message: 'Back online — syncing…',
              )
            : _BannerTile(
                key: const ValueKey('offline'),
                color: const Color(0xFFEF4444),    // red-500
                icon: Icons.wifi_off_rounded,
                message: 'No internet — working offline',
              ),
      ),
    );
  }
}

class _BannerTile extends StatelessWidget {
  const _BannerTile({
    super.key,
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
