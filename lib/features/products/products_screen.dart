import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../core/utils/stock_health.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/app_pressable.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/filter_chips.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/skeleton_loader.dart';

enum ProductSort {
  nameAsc('Name A-Z'),
  nameDesc('Name Z-A'),
  stockAsc('Stock Low-High'),
  stockDesc('Stock High-Low'),
  priceAsc('Price Low-High'),
  priceDesc('Price High-Low');
  
  final String label;
  const ProductSort(this.label);
}

enum StockFilter {
  all('All Stock'),
  critical('Critical (≤ 2)'),
  warning('Low Stock (3–5)'),
  outOfStock('Out of Stock (0)'),
  inStock('In Stock (> 5)');

  final String label;
  const StockFilter(this.label);
}

enum ProductTypeFilter {
  all('All Items'),
  physical('Physical Goods'),
  services('Services / Labor');

  final String label;
  const ProductTypeFilter(this.label);
}

/// Shared provider to request navigation to the Products list with the Low Stock filter pre-selected.
class ProductLowStockFilterNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void trigger() => state = true;
  void reset() => state = false;
  void set(bool value) => state = value;
}

final productLowStockFilterProvider =
    NotifierProvider<ProductLowStockFilterNotifier, bool>(
  ProductLowStockFilterNotifier.new,
);

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _query = '';
  int _filter = 0; // 0 = All; 1+ = category index
  ProductSort _sort = ProductSort.nameAsc;
  StockFilter _stockFilter = StockFilter.all;
  ProductTypeFilter _typeFilter = ProductTypeFilter.all;
  String? _selectedBrand;
  bool _addOpen = false; // speed-dial expanded state

  @override
  void initState() {
    super.initState();
    if (ref.read(productLowStockFilterProvider)) {
      _stockFilter = StockFilter.critical;
      _sort = ProductSort.stockAsc;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(productLowStockFilterProvider.notifier).reset();
      });
    }
  }

  List<Product> _apply(
    List<Product> products, {
    required String? category,
  }) {
    final filtered = products.where((p) {
      if (category != null && p.category != category) {
        return false;
      }
      switch (_stockFilter) {
        case StockFilter.all:
          break;
        case StockFilter.critical:
          if (p.isService || p.effectiveStockQty > criticalStockThreshold) {
            return false;
          }
          break;
        case StockFilter.warning:
          if (p.isService ||
              p.effectiveStockQty <= criticalStockThreshold ||
              p.effectiveStockQty > lowStockThreshold) {
            return false;
          }
          break;
        case StockFilter.outOfStock:
          if (p.isService || p.effectiveStockQty > 0) return false;
          break;
        case StockFilter.inStock:
          if (!p.isService && p.effectiveStockQty <= lowStockThreshold) {
            return false;
          }
          break;
      }
      if (_selectedBrand != null && p.brand != _selectedBrand) {
        return false;
      }
      switch (_typeFilter) {
        case ProductTypeFilter.all:
          break;
        case ProductTypeFilter.physical:
          if (p.isService) return false;
          break;
        case ProductTypeFilter.services:
          if (!p.isService) return false;
          break;
      }
      if (_query.isNotEmpty) {
        final q = _query.trim().toLowerCase();
        final matchMain = p.name.toLowerCase().contains(q) ||
            (p.barcode?.toLowerCase().contains(q) ?? false) ||
            (p.partNumber?.toLowerCase().contains(q) ?? false) ||
            (p.brand?.toLowerCase().contains(q) ?? false) ||
            (p.category?.toLowerCase().contains(q) ?? false);
        if (matchMain) return true;
        if (p.hasVariants) {
          return p.variants.any((v) =>
              v.name.toLowerCase().contains(q) ||
              (v.barcode?.toLowerCase().contains(q) ?? false) ||
              (v.sku?.toLowerCase().contains(q) ?? false) ||
              (v.partNumber?.toLowerCase().contains(q) ?? false));
        }
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case ProductSort.nameAsc: return a.name.compareTo(b.name);
        case ProductSort.nameDesc: return b.name.compareTo(a.name);
        case ProductSort.stockAsc: return a.effectiveStockQty.compareTo(b.effectiveStockQty);
        case ProductSort.stockDesc: return b.effectiveStockQty.compareTo(a.effectiveStockQty);
        case ProductSort.priceAsc: return a.sellingPrice.compareTo(b.sellingPrice);
        case ProductSort.priceDesc: return b.sellingPrice.compareTo(a.sellingPrice);
      }
    });

    return filtered;
  }

  void _toggleAdd() => setState(() => _addOpen = !_addOpen);

  void _selectAdd(String route) {
    setState(() => _addOpen = false);
    context.push(route);
  }

  void _openFilterPanel(BuildContext context, List<String> availableBrands) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;
    if (isWide) {
      showDialog(
        context: context,
        builder: (dialogCtx) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
            child: _ProductFilterSheet(
              currentSort: _sort,
              currentStock: _stockFilter,
              currentType: _typeFilter,
              currentBrand: _selectedBrand,
              availableBrands: availableBrands,
              onApply: ({
                required sort,
                required stock,
                required type,
                required brand,
              }) {
                setState(() {
                  _sort = sort;
                  _stockFilter = stock;
                  _typeFilter = type;
                  _selectedBrand = brand;
                });
              },
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetCtx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.85,
            ),
            child: _ProductFilterSheet(
              currentSort: _sort,
              currentStock: _stockFilter,
              currentType: _typeFilter,
              currentBrand: _selectedBrand,
              availableBrands: availableBrands,
              onApply: ({
                required sort,
                required stock,
                required type,
                required brand,
              }) {
                setState(() {
                  _sort = sort;
                  _stockFilter = stock;
                  _typeFilter = type;
                  _selectedBrand = brand;
                });
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(productLowStockFilterProvider, (_, next) {
      if (next && mounted) {
        setState(() {
          _stockFilter = StockFilter.critical;
          _sort = ProductSort.stockAsc;
        });
        ref.read(productLowStockFilterProvider.notifier).reset();
      }
    });

    final productsAsync = ref.watch(productListStreamProvider);
    final allProducts = productsAsync.value ?? [];
    final categories = ref.watch(categoryListStreamProvider).value ?? [];

    final availableBrands = allProducts
        .map((p) => p.brand?.trim())
        .where((b) => b != null && b.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final activeFilterCount = (_stockFilter != StockFilter.all ? 1 : 0) +
        (_selectedBrand != null ? 1 : 0) +
        (_typeFilter != ProductTypeFilter.all ? 1 : 0);

    final filterOptions = ['All', ...categories.map((c) => c.name)];
    final selectedIndex = _filter.clamp(0, filterOptions.length - 1);
    final selectedCategory =
        selectedIndex == 0 ? null : categories[selectedIndex - 1].name;

    final badges = <int, int>{};
    for (int i = 1; i < filterOptions.length; i++) {
      final cat = filterOptions[i];
      final catRedCount = allProducts
          .where((p) =>
              !p.isService &&
              p.category == cat &&
              p.effectiveStockQty <= criticalStockThreshold)
          .length;
      if (catRedCount > 0) {
        badges[i] = catRedCount;
      }
    }

    final totalRedCountAll = allProducts
        .where((p) =>
            !p.isService && p.effectiveStockQty <= criticalStockThreshold)
        .length;
    if (totalRedCountAll > 0) {
      badges[0] = totalRedCountAll;
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            tooltip: 'Filter & Sort',
            onPressed: () => _openFilterPanel(context, availableBrands),
            icon: Badge(
              isLabelVisible: activeFilterCount > 0,
              label: Text('$activeFilterCount'),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
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
              if (activeFilterCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (_stockFilter != StockFilter.all) ...[
                          _ActiveFilterPill(
                            label: _stockFilter.label,
                            onRemove: () =>
                                setState(() => _stockFilter = StockFilter.all),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_selectedBrand != null) ...[
                          _ActiveFilterPill(
                            label: 'Brand: $_selectedBrand',
                            onRemove: () =>
                                setState(() => _selectedBrand = null),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_typeFilter != ProductTypeFilter.all) ...[
                          _ActiveFilterPill(
                            label: _typeFilter.label,
                            onRemove: () => setState(
                                () => _typeFilter = ProductTypeFilter.all),
                          ),
                          const SizedBox(width: 8),
                        ],
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _stockFilter = StockFilter.all;
                              _selectedBrand = null;
                              _typeFilter = ProductTypeFilter.all;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilterChips(
                  options: filterOptions,
                  selectedIndex: selectedIndex,
                  badges: badges,
                  onSelected: (i) => setState(() => _filter = i),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: productsAsync.when(
                  skipLoadingOnReload: true,
                  skipLoadingOnRefresh: true,
                  loading: () {
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    final isWide = screenWidth >= 800;
                    if (isWide) {
                      return Shimmer(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: screenWidth >= 1300 ? 3 : 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 2.8,
                          ),
                          itemCount: 6,
                          itemBuilder: (_, _) => const SkeletonProductRow(),
                        ),
                      );
                    }
                    return Shimmer(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: 8,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, _) => const SkeletonProductRow(),
                      ),
                    );
                  },
                  error: (e, _) => EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load products',
                    body: '$e',
                    action: FilledButton.tonal(
                      onPressed: () => ref.invalidate(productListStreamProvider),
                      child: const Text('Retry'),
                    ),
                  ),
                  data: (products) {
                    final filtered = _apply(
                      products,
                      category: selectedCategory,
                    );
                    if (filtered.isEmpty) {
                      final hasAnyFilter = activeFilterCount > 0 ||
                          selectedCategory != null ||
                          _query.isNotEmpty;
                      return EmptyState(
                        icon: hasAnyFilter
                            ? Icons.filter_alt_off_rounded
                            : Icons.inventory_2_outlined,
                        title: 'No products found',
                        body: hasAnyFilter
                            ? 'No products match your active filters or search terms.'
                            : 'Add products to get started.',
                        action: hasAnyFilter
                            ? FilledButton.tonal(
                                onPressed: () {
                                  setState(() {
                                    _query = '';
                                    _filter = 0;
                                    _stockFilter = StockFilter.all;
                                    _selectedBrand = null;
                                    _typeFilter = ProductTypeFilter.all;
                                  });
                                },
                                child: const Text('Reset all filters'),
                              )
                            : FilledButton(
                                onPressed: () =>
                                    context.push(RoutePaths.addProduct),
                                child: const Text('Add a product'),
                              ),
                      );
                    }
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    final isWide = screenWidth >= 800;

                    if (isWide) {
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: screenWidth >= 1300 ? 3 : 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 2.8,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _ProductTile(product: filtered[i]),
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
    final stockColor = stockHealth(product.effectiveStockQty).color;

    return GestureDetector(
      onTap: () => context.push(RoutePaths.productDetail, extra: product.id),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _TileImage(
              imageUrl: product.imageUrl,
              imagePath: product.imagePath,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.hasVariants && product.variants.isNotEmpty
                                ? '${product.effectiveStockQty} in stock (${product.variants.length} vars)'
                                : '${product.stockQty} in stock',
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
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withValues(alpha: 0.25)),
              ),
              child: Text(
                product.hasVariants && product.variants.isNotEmpty
                    ? ((product.minSellingPrice - product.maxSellingPrice).abs() < 0.01
                        ? formatPeso(product.minSellingPrice)
                        : '${formatPeso(product.minSellingPrice)} - ${formatPeso(product.maxSellingPrice)}')
                    : formatPeso(product.sellingPrice),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  fontSize: 13,
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
  const _TileImage({this.imageUrl, this.imagePath});

  final String? imageUrl;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return AppImage(
      imageUrl: imageUrl,
      imagePath: imagePath,
      width: 52,
      height: 52,
      borderRadius: BorderRadius.circular(12),
      fit: BoxFit.cover,
      placeholderIcon: Icons.inventory_2_outlined,
      placeholderIconSize: 26,
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
        AppPressable(
          onTap: onToggle,
          child: FloatingActionButton(
            heroTag: 'products_add_fab',
            onPressed: onToggle,
            child: AnimatedRotation(
              turns: open ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(open ? Icons.close_rounded : Icons.add_rounded, size: 28),
            ),
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
      child: AppPressable(
        onTap: onTap,
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
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Icon(icon, color: primary, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterPill extends StatelessWidget {
  const _ActiveFilterPill({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductFilterSheet extends StatefulWidget {
  const _ProductFilterSheet({
    required this.currentSort,
    required this.currentStock,
    required this.currentType,
    required this.currentBrand,
    required this.availableBrands,
    required this.onApply,
  });

  final ProductSort currentSort;
  final StockFilter currentStock;
  final ProductTypeFilter currentType;
  final String? currentBrand;
  final List<String> availableBrands;
  final void Function({
    required ProductSort sort,
    required StockFilter stock,
    required ProductTypeFilter type,
    required String? brand,
  }) onApply;

  @override
  State<_ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<_ProductFilterSheet> {
  late ProductSort _sort = widget.currentSort;
  late StockFilter _stock = widget.currentStock;
  late ProductTypeFilter _type = widget.currentType;
  late String? _brand = widget.currentBrand;

  bool get _hasActiveFilters =>
      _stock != StockFilter.all ||
      _type != ProductTypeFilter.all ||
      _brand != null ||
      _sort != ProductSort.nameAsc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sort & Filter',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_hasActiveFilters)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _sort = ProductSort.nameAsc;
                      _stock = StockFilter.all;
                      _type = ProductTypeFilter.all;
                      _brand = null;
                    });
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Reset All'),
                ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Scrollable filter categories
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Stock Status
                _sectionHeader(
                    context, 'Stock Status', Icons.inventory_2_outlined),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: StockFilter.values.map((opt) {
                    final isSelected = _stock == opt;
                    Color? dotColor;
                    if (opt == StockFilter.critical) dotColor = AppColors.danger;
                    if (opt == StockFilter.warning) dotColor = AppColors.expense;
                    if (opt == StockFilter.inStock) dotColor = AppColors.active;
                    if (opt == StockFilter.outOfStock) dotColor = Colors.grey;

                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (dotColor != null) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(opt.label),
                        ],
                      ),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: primary,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      onSelected: (_) => setState(() => _stock = opt),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 2. Brand
                if (widget.availableBrands.isNotEmpty) ...[
                  _sectionHeader(
                      context, 'Brand', Icons.branding_watermark_outlined),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All Brands'),
                        selected: _brand == null,
                        showCheckmark: false,
                        selectedColor: primary,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: _brand == null
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                        onSelected: (_) => setState(() => _brand = null),
                      ),
                      ...widget.availableBrands.map((b) {
                        final isSelected = _brand == b;
                        return ChoiceChip(
                          label: Text(b),
                          selected: isSelected,
                          showCheckmark: false,
                          selectedColor: primary,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                          onSelected: (_) =>
                              setState(() => _brand = isSelected ? null : b),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. Product Type
                _sectionHeader(context, 'Item Type', Icons.category_outlined),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ProductTypeFilter.values.map((opt) {
                    final isSelected = _type == opt;
                    return ChoiceChip(
                      label: Text(opt.label),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: primary,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      onSelected: (_) => setState(() => _type = opt),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 4. Sort By
                _sectionHeader(context, 'Sort By', Icons.sort_rounded),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ProductSort.values.map((opt) {
                    final isSelected = _sort == opt;
                    return ChoiceChip(
                      label: Text(opt.label),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: primary,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      onSelected: (_) => setState(() => _sort = opt),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        // Action Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () {
              widget.onApply(
                sort: _sort,
                stock: _stock,
                type: _type,
                brand: _brand,
              );
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Apply Filters',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}




