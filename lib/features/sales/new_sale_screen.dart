import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../core/utils/stock_health.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/barcode_scanner_screen.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/search_field.dart';
import 'cart_controller.dart';
import 'cart_sheet.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  String _query = '';
  // null = All; 'service' = services only; otherwise = category name
  String? _categoryFilter;

  List<Product> _apply(List<Product> products) {
    return products.where((p) {
      // Category filter
      if (_categoryFilter != null) {
        if (_categoryFilter == '__service__') {
          if (!p.isService) return false;
        } else {
          if (p.category != _categoryFilter) return false;
        }
      }
      // Search
      if (_query.isNotEmpty) {
        return p.name.toLowerCase().contains(_query.toLowerCase());
      }
      return true;
    }).toList();
  }

  Future<void> _scanToAdd(List<Product> products) async {
    final code = await scanBarcode(context);
    if (code == null) return;
    final match = products.where((p) => p.barcode == code).firstOrNull;
    if (!mounted) return;
    if (match == null) {
      _snack('No product with barcode $code');
      return;
    }
    final allowOversell = ref.read(businessSettingsStreamProvider).value
            ?.allowSellWhenOutOfStock ??
        false;
    if (!match.isService && match.stockQty <= 0 && !allowOversell) {
      _snack('${match.name} is out of stock');
      return;
    }
    ref.read(cartControllerProvider.notifier).add(match);
    _snack('Added ${match.name}');
  }

  Future<void> _openCart() async {
    if (ref.read(cartControllerProvider).isEmpty) {
      _snack('Cart is empty — add products first');
      return;
    }
    final sale = await showCartSheet(context);
    if (!mounted || sale == null) return;
    _snack('Sale ${sale.saleNumber} recorded');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListStreamProvider);
    final categoriesAsync = ref.watch(categoryListStreamProvider);
    final cart = ref.watch(cartControllerProvider);
    final allowOversell = ref
            .watch(businessSettingsStreamProvider)
            .value
            ?.allowSellWhenOutOfStock ??
        false;
    final products = productsAsync.value ?? [];
    final categories = categoriesAsync.value ?? [];
    final itemCount = cart.fold(0, (sum, l) => sum + l.quantity);
    final cartTotal = cart.fold<double>(0, (sum, l) => sum + l.lineTotal);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Build filter options: All + user categories + Services (if any service categories exist)
    final productCategories = categories.where((c) => !c.isService).toList();
    final serviceCategories = categories.where((c) => c.isService).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Sale',
                    style: AppTextStyles.headingMedium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Select items to add to cart',
                    style: AppTextStyles.body.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Search + scan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SearchField(
                hint: 'Search products...',
                onChanged: (v) => setState(() => _query = v),
                trailing: IconButton.filled(
                  onPressed: () => _scanToAdd(products),
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size(46, 46),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Dynamic category chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // ALL chip
                  _CategoryChip(
                    label: 'All',
                    selected: _categoryFilter == null,
                    onTap: () => setState(() => _categoryFilter = null),
                  ),
                  // Product categories
                  for (final cat in productCategories)
                    _CategoryChip(
                      label: cat.name,
                      selected: _categoryFilter == cat.name,
                      onTap: () => setState(() => _categoryFilter = cat.name),
                    ),
                  // Services (if any service categories exist)
                  if (serviceCategories.isNotEmpty)
                    _CategoryChip(
                      label: 'Services',
                      selected: _categoryFilter == '__service__',
                      onTap: () =>
                          setState(() => _categoryFilter = '__service__'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Product grid
            Expanded(
              child: productsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (all) {
                  final filtered = _apply(all);
                  if (filtered.isEmpty) {
                    return const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No products',
                      body: 'No products match your search.',
                    );
                  }
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      itemCount > 0 ? 100 : 16,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final product = filtered[i];
                      final line = cart
                          .where((l) => l.productId == product.id)
                          .firstOrNull;
                      final cartQty = line?.quantity ?? 0;
                      final maxQty = product.isService || allowOversell
                          ? 999
                          : product.stockQty;
                      final outOfStock = !product.isService &&
                          product.stockQty <= 0 &&
                          !allowOversell;
                      return _ProductCard(
                        product: product,
                        quantity: cartQty,
                        outOfStock: outOfStock,
                        atStockLimit: !product.isService &&
                            !allowOversell &&
                            cartQty >= product.stockQty,
                        onAdd: outOfStock || cartQty >= maxQty
                            ? null
                            : () => ref
                                .read(cartControllerProvider.notifier)
                                .add(product),
                        onRemove: () => ref
                            .read(cartControllerProvider.notifier)
                            .decrement(product.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Floating cart bar
      floatingActionButton: itemCount > 0
          ? _FloatingCartBar(
              itemCount: itemCount,
              total: cartTotal,
              onTap: _openCart,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ─── Category chip ────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? primary : primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? primary : primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Floating cart bar ────────────────────────────────────────────────────────
class _FloatingCartBar extends StatelessWidget {
  const _FloatingCartBar({
    required this.itemCount,
    required this.total,
    required this.onTap,
  });

  final int itemCount;
  final double total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, theme.colorScheme.secondary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$itemCount item${itemCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'View Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatPeso(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Product card ─────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.outOfStock,
    required this.atStockLimit,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final int quantity;
  final bool outOfStock;
  final bool atStockLimit;
  final VoidCallback? onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final stockColor = stockHealth(product.stockQty).color;
    final inCart = quantity > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: outOfStock
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.5)
              : inCart
                  ? primary
                  : theme.colorScheme.outlineVariant,
          width: inCart && !outOfStock ? 2.0 : 1.0,
        ),
        color: outOfStock
            ? theme.colorScheme.surface.withValues(alpha: 0.6)
            : theme.colorScheme.surface,
        boxShadow: inCart && !outOfStock
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image / placeholder
                  _CardImage(
                    imagePath: product.imagePath,
                    outOfStock: outOfStock,
                  ),
                  // Cart quantity badge
                  if (inCart && !outOfStock)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'x$quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  // Service badge
                  if (product.isService)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'SERVICE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: outOfStock
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatPeso(product.sellingPrice),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w900,
                      color: outOfStock
                          ? theme.colorScheme.onSurfaceVariant
                          : primary,
                      fontSize: 14,
                    ),
                  ),
                  if (!product.isService) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: stockColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          outOfStock
                              ? 'Out of stock'
                              : '${product.stockQty} in stock',
                          style: TextStyle(
                            fontSize: 10,
                            color: outOfStock
                                ? theme.colorScheme.error
                                : stockColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (outOfStock)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(36),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          disabledForegroundColor:
                              theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                        ),
                        child: const Text('Out of Stock',
                            style: TextStyle(fontSize: 11)),
                      ),
                    )
                  else if (quantity == 0)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onAdd,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(36),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 16),
                            SizedBox(width: 4),
                            Text('ADD',
                                style:
                                    TextStyle(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    )
                  else
                    _CardStepper(
                      quantity: quantity,
                      onAdd: atStockLimit ? null : onAdd,
                      onRemove: onRemove,
                      atLimit: atStockLimit,
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

// ─── Card image with out-of-stock watermark ───────────────────────────────────
class _CardImage extends StatelessWidget {
  const _CardImage({required this.imagePath, required this.outOfStock});

  final String? imagePath;
  final bool outOfStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget base;

    if (imagePath != null && File(imagePath!).existsSync()) {
      base = Image.file(File(imagePath!), fit: BoxFit.cover);
    } else {
      base = Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.inventory_2_outlined,
            size: 44,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    if (!outOfStock) return base;

    // Out-of-stock overlay with watermark
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.grey.withValues(alpha: 0.5),
            BlendMode.saturation,
          ),
          child: base,
        ),
        Container(color: Colors.black.withValues(alpha: 0.35)),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white30),
            ),
            child: const Text(
              'NOT AVAILABLE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Quantity stepper ─────────────────────────────────────────────────────────
class _CardStepper extends StatelessWidget {
  const _CardStepper({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.atLimit,
  });

  final int quantity;
  final VoidCallback? onAdd;
  final VoidCallback onRemove;
  final bool atLimit;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onRemove,
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(10)),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.remove, size: 16),
            ),
          ),
          Text(
            '$quantity',
            style: AppTextStyles.body
                .copyWith(fontWeight: FontWeight.w900, color: primary),
          ),
          InkWell(
            onTap: onAdd,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(10)),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.add,
                size: 16,
                color: atLimit
                    ? Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
