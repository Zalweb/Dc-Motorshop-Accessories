import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/filter_chips.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/search_field.dart';
import '../../core/utils/stock_health.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _query = '';
  int _filter = 0; // 0 = All; otherwise index into the user's categories + 1
  bool _addOpen = false; // speed-dial expanded state

  List<Product> _apply(List<Product> products, String? category) {
    return products.where((p) {
      if (category != null && p.category != category) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            (p.barcode?.contains(q) ?? false) ||
            (p.category?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  void _toggleAdd() => setState(() => _addOpen = !_addOpen);

  void _selectAdd(String route) {
    setState(() => _addOpen = false);
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListStreamProvider);
    final categories = ref.watch(categoryListStreamProvider).value ?? [];

    final filterOptions = ['All', ...categories.map((c) => c.name)];
    final selectedIndex = _filter.clamp(0, filterOptions.length - 1);
    final selectedCategory =
        selectedIndex == 0 ? null : categories[selectedIndex - 1].name;

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: _AddSpeedDial(
        open: _addOpen,
        onToggle: _toggleAdd,
        onSelect: _selectAdd,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SearchField(
                  hint: 'Search products...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilterChips(
                  options: filterOptions,
                  selectedIndex: selectedIndex,
                  onSelected: (i) => setState(() => _filter = i),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: productsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (products) {
                    final filtered = _apply(products, selectedCategory);
                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No products found',
                        body: 'Add products to get started.',
                        action: FilledButton(
                          onPressed: () => context.push(RoutePaths.addProduct),
                          child: const Text('Add a product'),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _ProductTile(product: filtered[i]),
                    );
                  },
                ),
              ),
            ],
          ),
          // Dim the page behind the expanded speed dial; tap to dismiss.
          if (_addOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleAdd,
                child: const ColoredBox(color: Color(0x99000000)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final stockColor = stockHealth(product.stockQty).color;

    return GestureDetector(
      onTap: () => context.push(RoutePaths.productDetail, extra: product.id),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            _TileImage(imagePath: product.imagePath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style:
                        AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category ?? 'Uncategorized',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!product.isService) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${product.stockQty} in stock',
                            style: TextStyle(
                              fontSize: 11,
                              color: stockColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Price in an elegant capsule badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.25)),
              ),
              child: Text(
                formatPeso(product.sellingPrice),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileImage extends StatelessWidget {
  const _TileImage({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imagePath != null && File(imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(imagePath!),
            width: 52, height: 52, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Expanding "speed dial" add menu: the main FAB fans out into labeled action
/// buttons (Add Product / Bulk Add / Categories) and flips to a close icon.
class _AddSpeedDial extends StatelessWidget {
  const _AddSpeedDial({
    required this.open,
    required this.onToggle,
    required this.onSelect,
  });

  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (open) ...[
          _SpeedDialItem(
            label: 'Categories',
            icon: Icons.account_tree_rounded,
            onTap: () => onSelect(RoutePaths.categories),
          ),
          const SizedBox(height: 14),
          _SpeedDialItem(
            label: 'Bulk Add',
            icon: Icons.layers_rounded,
            onTap: () => onSelect(RoutePaths.bulkAdd),
          ),
          const SizedBox(height: 14),
          _SpeedDialItem(
            label: 'Add Product',
            icon: Icons.add_box_rounded,
            onTap: () => onSelect(RoutePaths.addProduct),
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          heroTag: 'products_add_fab',
          onPressed: onToggle,
          child: AnimatedRotation(
            turns: open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(open ? Icons.close_rounded : Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }
}

class _SpeedDialItem extends StatelessWidget {
  const _SpeedDialItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surfaceContainerHighest;
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    // Subtle scale + fade entrance each time the dial opens.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: 0.85 + 0.15 * t, alignment: Alignment.centerRight, child: child),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Icon(icon, color: primary, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

