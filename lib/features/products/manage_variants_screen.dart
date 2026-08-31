import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/product.dart';
import 'widgets/variant_builder_widget.dart';

/// Full-screen or modal page to configure Shopee-style variations.
class ManageVariantsScreen extends StatefulWidget {
  const ManageVariantsScreen({
    super.key,
    required this.initialData,
    this.productName,
    this.defaultCostPrice = 0,
    this.defaultSellingPrice = 0,
    this.defaultStock = 0,
  });

  final VariantBuilderData initialData;
  final String? productName;
  final double defaultCostPrice;
  final double defaultSellingPrice;
  final int defaultStock;

  @override
  State<ManageVariantsScreen> createState() => _ManageVariantsScreenState();
}

class _ManageVariantsScreenState extends State<ManageVariantsScreen> {
  late VariantBuilderData _data;

  @override
  void initState() {
    super.initState();
    // Clone initial data
    _data = VariantBuilderData(
      hasVariants: widget.initialData.hasVariants,
      variation1Name: widget.initialData.variation1Name,
      variation1Options: List.from(widget.initialData.variation1Options),
      variation2Name: widget.initialData.variation2Name,
      variation2Options: List.from(widget.initialData.variation2Options),
      variants: widget.initialData.variants
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

    // If opening for first time with no variants, enable them
    if (!_data.hasVariants && _data.variants.isEmpty) {
      _data.hasVariants = true;
    }
    if (_data.variation1Name.trim().isEmpty) {
      _data.variation1Name = 'Variation 1';
    }
  }

  void _clearAllVariants() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove All Variations?'),
        content: const Text(
          'This will disable variations and revert this product to a single standard item with one price and stock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _data.hasVariants = false;
                _data.variation1Options.clear();
                _data.variation2Options.clear();
                _data.variants.clear();
              });
              Navigator.of(context).pop(_data);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remove Variations'),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_data.variants.isEmpty) {
      _data.hasVariants = false;
      _data.variation1Options.clear();
      _data.variation2Options.clear();
      _data.variants.clear();
    }
    Navigator.of(context).pop(_data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final hasActiveVariants = _data.hasVariants && _data.variants.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName != null ? 'Variations: ${widget.productName}' : 'Product Variations'),
        actions: [
          if (hasActiveVariants)
            TextButton(
              onPressed: _clearAllVariants,
              child: Text(
                'Disable',
                style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                hasActiveVariants
                    ? 'SAVE VARIATIONS (${_data.variants.length})'
                    : 'SAVE (NO VARIATIONS)',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          VariantBuilderWidget(
            data: _data,
            initialCostPrice: widget.defaultCostPrice,
            initialSellingPrice: widget.defaultSellingPrice,
            initialStock: widget.defaultStock,
            onChanged: () => setState(() {}),
          ),
        ],
      ),
    );
  }
}
