import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../core/utils/stock_health.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/glass_container.dart';
import 'add_product_screen.dart';

import 'manage_variants_screen.dart';
import 'widgets/variant_builder_widget.dart';

/// Read-only product detail. Reactively follows the product list so edits made
/// via the header's edit button reflect immediately.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  Future<void> _manageVariants(BuildContext context, WidgetRef ref, Product product) async {
    final v1List = <String>[];
    final v2List = <String>[];
    for (final v in product.variants) {
      if (v.option1 != null && !v1List.contains(v.option1)) v1List.add(v.option1!);
      if (v.option2 != null && !v2List.contains(v.option2)) v2List.add(v.option2!);
    }

    final initialData = VariantBuilderData(
      hasVariants: product.hasVariants,
      variation1Name: product.variation1Name ?? 'Color',
      variation1Options: v1List,
      variation2Name: product.variation2Name ?? 'Size',
      variation2Options: v2List,
      variants: product.variants
          .map((v) => ProductVariant()
            ..uid = v.uid
            ..name = v.name
            ..option1 = v.option1
            ..option2 = v.option2
            ..sellingPrice = v.sellingPrice
            ..costPrice = v.costPrice
            ..stockQty = v.stockQty
            ..barcode = v.barcode
            ..imagePath = v.imagePath
            ..imageUrl = v.imageUrl)
          .toList(),
    );

    final result = await Navigator.of(context).push<VariantBuilderData>(
      MaterialPageRoute(
        builder: (_) => ManageVariantsScreen(
          initialData: initialData,
          productName: product.name,
          defaultCostPrice: product.costPrice,
          defaultSellingPrice: product.sellingPrice,
          defaultStock: product.stockQty,
        ),
      ),
    );

    if (result != null) {
      final hasVariants = result.hasVariants && result.variants.isNotEmpty;
      product
        ..hasVariants = hasVariants
        ..variation1Name = hasVariants ? result.variation1Name : null
        ..variation2Name = (hasVariants && result.variation2Options.isNotEmpty) ? result.variation2Name : null
        ..variants = hasVariants ? result.variants : []
        ..stockQty = hasVariants ? result.variants.fold(0, (sum, v) => sum + v.stockQty) : product.stockQty;
      await ref.read(productRepositoryProvider).save(product);
    }
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? '
          'This will remove it from the catalog and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(productRepositoryProvider).delete(product.uid);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${product.name}"')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListStreamProvider).value ?? [];
    final product = products.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.push(
              RoutePaths.addProduct,
              extra: AddProductArgs(editProduct: product),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Delete Product',
            onPressed: () => _deleteProduct(context, ref, product),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _Header(product: product),
          const SizedBox(height: 20),
          if (!product.isService) ...[
            _VariantsCard(
              product: product,
              onManage: () => _manageVariants(context, ref, product),
            ),
            const SizedBox(height: 16),
          ],
          _PricingCard(product: product),
          const SizedBox(height: 16),
          _InventoryCard(product: product),
          const SizedBox(height: 16),
          _DetailsCard(product: product),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _ProductImage(
          imageUrl: product.imageUrl,
          imagePath: product.imagePath,
        ),
        const SizedBox(height: 16),
        Text(
          product.name,
          textAlign: TextAlign.center,
          style: AppTextStyles.headingMedium,
        ),
        if (product.description != null && product.description!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            product.description!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.imageUrl, this.imagePath});

  final String? imageUrl;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return AppImage(
      imageUrl: imageUrl,
      imagePath: imagePath,
      width: 160,
      height: 160,
      borderRadius: BorderRadius.circular(24),
      fit: BoxFit.cover,
      placeholderIcon: Icons.inventory_2_outlined,
      placeholderIconSize: 56,
    );
  }
}

class _VariantsCard extends StatelessWidget {
  const _VariantsCard({required this.product, required this.onManage});

  final Product product;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (!product.hasVariants || product.variants.isEmpty) {
      return _Card(
        title: 'Variations',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No variations configured for this product.',
              style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('+ Add Variations (Color, Size, etc.)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                side: BorderSide(color: primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return _Card(
      title: 'Variations (${product.variants.length})',
      child: Column(
        children: [
          for (final variant in product.variants)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      variant.name,
                      style: AppTextStyles.labelCaps.copyWith(color: primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (variant.barcode != null && variant.barcode!.isNotEmpty)
                    Text(
                      '#${variant.barcode}',
                      style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatPeso(variant.sellingPrice),
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '${variant.stockQty} in stock',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: variant.stockQty > 0 ? AppColors.active : AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          FilledButton.tonalIcon(
            onPressed: onManage,
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Manage Variations & Stock'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (product.hasVariants && product.variants.isNotEmpty) {
      final minP = product.minSellingPrice;
      final maxP = product.maxSellingPrice;
      final priceDisplay = (minP - maxP).abs() < 0.01
          ? formatPeso(minP)
          : '${formatPeso(minP)} - ${formatPeso(maxP)}';

      return _Card(
        title: 'Pricing Summary',
        child: Row(
          children: [
            Expanded(
              child: _PriceColumn(
                label: 'PRICE RANGE',
                value: priceDisplay,
              ),
            ),
            Expanded(
              child: _PriceColumn(
                label: 'TOTAL VARIANTS',
                value: '${product.variants.length}',
              ),
            ),
          ],
        ),
      );
    }

    final profit = product.sellingPrice - product.costPrice;
    final marginPct =
        product.sellingPrice > 0 ? profit / product.sellingPrice * 100 : 0;
    final marginColor = profit < 0 ? AppColors.danger : AppColors.active;

    return _Card(
      title: 'Pricing',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _PriceColumn(
              label: 'SELLING',
              value: formatPeso(product.sellingPrice),
            ),
          ),
          Expanded(
            child: _PriceColumn(
              label: 'COST',
              value: formatPeso(product.costPrice),
            ),
          ),
          Expanded(
            child: _PriceColumn(
              label: 'MARGIN',
              value: '${marginPct.toStringAsFixed(0)}%',
              valueColor: marginColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelCaps
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (product.isService) {
      return _Card(
        title: 'Inventory',
        child: Text(
          'Service — stock not tracked',
          style: AppTextStyles.body
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final qty = product.effectiveStockQty;
    final health = stockHealth(qty);

    return _Card(
      title: 'Inventory',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            product.hasVariants && product.variants.isNotEmpty
                ? '$qty PCS (Total)'
                : '$qty PCS',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: health.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                health.label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: health.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final created = DateFormat('MMM d, yyyy').format(product.createdAt);

    return _Card(
      title: 'Details',
      child: Column(
        children: [
          _Row(label: 'Barcode', value: product.barcode ?? '—'),
          const SizedBox(height: 12),
          _Row(label: 'Brand', value: product.brand ?? '—'),
          const SizedBox(height: 12),
          _Row(label: 'Part number', value: product.partNumber ?? '—'),
          const SizedBox(height: 12),
          _Row(label: 'Created', value: created),
        ],
      ),
    );
  }
}

/// Glassmorphic card with an all-caps section title.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.labelCaps
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
