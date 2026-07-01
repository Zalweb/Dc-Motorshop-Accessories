import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/glass_container.dart';
import 'add_product_screen.dart';
import '../../core/utils/stock_health.dart';

/// Read-only product detail. Reactively follows the product list so edits made
/// via the header's edit button reflect immediately.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _Header(product: product),
          const SizedBox(height: 20),
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
        _ProductImage(imagePath: product.imagePath),
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
  const _ProductImage({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imagePath != null && File(imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.file(File(imagePath!),
            width: 160, height: 160, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: 56,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
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

    final qty = product.stockQty;
    final health = stockHealth(qty);

    return _Card(
      title: 'Inventory',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$qty PCS',
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
