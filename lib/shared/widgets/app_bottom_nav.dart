import 'package:flutter/material.dart';

import 'package:iconoir_flutter/iconoir_flutter.dart' hide Text, List;
import 'glass_container.dart';

class BottomNavSpec {
  const BottomNavSpec(this.label, this.iconBuilder);
  final String label;
  final Widget Function(Color) iconBuilder;
}

final _navItems = <BottomNavSpec>[
  BottomNavSpec('Dashboard', (c) => ViewGrid(color: c, width: 24, height: 24)),
  BottomNavSpec('Sales', (c) => Reports(color: c, width: 24, height: 24)),
  BottomNavSpec('New Sale', (c) => Plus(color: c, width: 26, height: 26)),
  BottomNavSpec('Products', (c) => BoxIso(color: c, width: 24, height: 24)),
  BottomNavSpec('More', (c) => MenuScale(color: c, width: 24, height: 24)),
];

const _newSaleIndex = 2;

/// Bottom navigation with an elevated center FAB for New Sale
/// styled as a frosted glassmorphic overlay.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
        child: SafeArea(
          top: false,
          bottom: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                if (i == _newSaleIndex) return _CenterFab(onTap: () => onTap(i));
                return _NavItem(
                  spec: _navItems[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final BottomNavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            spec.iconBuilder(color),
            const SizedBox(height: 4),
            Text(
              spec.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  const _CenterFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(child: Cart(color: Colors.white, width: 26, height: 26)),
          ),
        ),
      ),
    );
  }
}
