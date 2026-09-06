import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'tactile_button.dart';

/// Horizontal selectable pill chips (ALL / PRODUCTS / SERVICES).
class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.badges,
    this.leading,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Optional badge counts keyed by option index (e.g. {1: 5} for Low Stock).
  final Map<int, int>? badges;

  /// Optional leading widget (e.g. sort button) that scrolls along with the chips.
  final Widget? leading;

  static String _formatBadge(int count) {
    if (count < 1000) return '$count';
    final s = count.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLeading = leading != null;
    return SizedBox(
      height: 58, // extra height for badge overflow above chips
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none, // allow badge to render above the list bounds
        padding: const EdgeInsets.only(top: 14), // push chips down so badge has room above
        itemCount: options.length + (hasLeading ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (hasLeading && index == 0) {
            return leading!;
          }
          final i = hasLeading ? index - 1 : index;
          final selected = i == selectedIndex;
          final badgeCount = badges?[i] ?? 0;
          return TactileButton(
            onTap: () => onSelected(i),
            scaleDown: 0.94,
            hoverScale: 1.04,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Text(
                    options[i].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected
                          ? (theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: 0,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 19, minHeight: 19),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.danger.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _formatBadge(badgeCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
