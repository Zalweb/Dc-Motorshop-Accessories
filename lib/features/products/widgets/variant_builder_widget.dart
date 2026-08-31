import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/barcode_scanner_screen.dart';

class VariantBuilderData {
  VariantBuilderData({
    this.hasVariants = false,
    this.variation1Name = 'Variation 1',
    List<String>? variation1Options,
    this.variation2Name = 'Variation 2',
    List<String>? variation2Options,
    List<ProductVariant>? variants,
  })  : variation1Options = variation1Options ?? [],
        variation2Options = variation2Options ?? [],
        variants = variants ?? [];

  bool hasVariants;
  String variation1Name;
  List<String> variation1Options;
  String variation2Name;
  List<String> variation2Options;
  List<ProductVariant> variants;

  void rebuildMatrix({double defaultPrice = 0, double defaultCost = 0, int defaultStock = 0}) {
    final newVariants = <ProductVariant>[];
    final opts1 = variation1Options.where((o) => o.trim().isNotEmpty).toList();
    final opts2 = variation2Options.where((o) => o.trim().isNotEmpty).toList();

    if (opts1.isEmpty && opts2.isEmpty) {
      variants = [];
      return;
    }

    if (opts1.isNotEmpty && opts2.isEmpty) {
      for (final o1 in opts1) {
        final existing = variants.where((v) => v.option1 == o1 && (v.option2 == null || v.option2!.isEmpty)).firstOrNull;
        newVariants.add(
          ProductVariant()
            ..uid = existing?.uid ?? ProductVariant().uid
            ..name = o1
            ..option1 = o1
            ..option2 = null
            ..sku = existing?.sku
            ..barcode = existing?.barcode
            ..partNumber = existing?.partNumber
            ..sellingPrice = existing?.sellingPrice ?? defaultPrice
            ..costPrice = existing?.costPrice ?? defaultCost
            ..stockQty = existing?.stockQty ?? defaultStock
            ..reorderLevel = existing?.reorderLevel ?? 0
            ..isActive = existing?.isActive ?? true
            ..imagePath = existing?.imagePath,
        );
      }
    } else if (opts1.isEmpty && opts2.isNotEmpty) {
      for (final o2 in opts2) {
        final existing = variants.where((v) => v.option2 == o2 && (v.option1 == null || v.option1!.isEmpty)).firstOrNull;
        newVariants.add(
          ProductVariant()
            ..uid = existing?.uid ?? ProductVariant().uid
            ..name = o2
            ..option1 = null
            ..option2 = o2
            ..sku = existing?.sku
            ..barcode = existing?.barcode
            ..partNumber = existing?.partNumber
            ..sellingPrice = existing?.sellingPrice ?? defaultPrice
            ..costPrice = existing?.costPrice ?? defaultCost
            ..stockQty = existing?.stockQty ?? defaultStock
            ..reorderLevel = existing?.reorderLevel ?? 0
            ..isActive = existing?.isActive ?? true
            ..imagePath = existing?.imagePath,
        );
      }
    } else {
      for (final o1 in opts1) {
        for (final o2 in opts2) {
          final existing = variants.where((v) => v.option1 == o1 && v.option2 == o2).firstOrNull;
          newVariants.add(
            ProductVariant()
              ..uid = existing?.uid ?? ProductVariant().uid
              ..name = '$o1 / $o2'
              ..option1 = o1
              ..option2 = o2
              ..sku = existing?.sku
              ..barcode = existing?.barcode
              ..partNumber = existing?.partNumber
              ..sellingPrice = existing?.sellingPrice ?? defaultPrice
              ..costPrice = existing?.costPrice ?? defaultCost
              ..stockQty = existing?.stockQty ?? defaultStock
              ..reorderLevel = existing?.reorderLevel ?? 0
              ..isActive = existing?.isActive ?? true
              ..imagePath = existing?.imagePath,
          );
        }
      }
    }
    variants = newVariants;
  }
}

class VariantBuilderWidget extends StatefulWidget {
  const VariantBuilderWidget({
    super.key,
    required this.data,
    required this.onChanged,
    this.initialCostPrice = 0,
    this.initialSellingPrice = 0,
    this.initialStock = 0,
  });

  final VariantBuilderData data;
  final VoidCallback onChanged;
  final double initialCostPrice;
  final double initialSellingPrice;
  final int initialStock;

  @override
  State<VariantBuilderWidget> createState() => _VariantBuilderWidgetState();
}

class _VariantBuilderWidgetState extends State<VariantBuilderWidget> {
  final _opt1Input = TextEditingController();
  final _opt2Input = TextEditingController();
  final _batchPrice = TextEditingController();
  final _batchCost = TextEditingController();
  final _batchStock = TextEditingController();
  late TextEditingController _v1NameCtrl;
  late TextEditingController _v2NameCtrl;

  bool _enableTier2 = false;

  @override
  void initState() {
    super.initState();
    _v1NameCtrl = TextEditingController(text: widget.data.variation1Name);
    _v2NameCtrl = TextEditingController(text: widget.data.variation2Name);
    _batchPrice.text = widget.initialSellingPrice > 0 ? widget.initialSellingPrice.toString() : '';
    _batchCost.text = widget.initialCostPrice > 0 ? widget.initialCostPrice.toString() : '';
    _batchStock.text = widget.initialStock > 0 ? widget.initialStock.toString() : '';

    _enableTier2 = widget.data.variation2Options.isNotEmpty;

    // Direct matrix rebuild
    widget.data.rebuildMatrix(
      defaultPrice: double.tryParse(_batchPrice.text) ?? widget.initialSellingPrice,
      defaultCost: double.tryParse(_batchCost.text) ?? widget.initialCostPrice,
      defaultStock: int.tryParse(_batchStock.text) ?? widget.initialStock,
    );
  }

  @override
  void didUpdateWidget(covariant VariantBuilderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.variation1Name != _v1NameCtrl.text) {
      _v1NameCtrl.text = widget.data.variation1Name;
    }
    if (widget.data.variation2Name != _v2NameCtrl.text) {
      _v2NameCtrl.text = widget.data.variation2Name;
    }
  }

  @override
  void dispose() {
    _opt1Input.dispose();
    _opt2Input.dispose();
    _batchPrice.dispose();
    _batchCost.dispose();
    _batchStock.dispose();
    _v1NameCtrl.dispose();
    _v2NameCtrl.dispose();
    super.dispose();
  }

  void _addOption1(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty || widget.data.variation1Options.contains(trimmed)) return;
    setState(() {
      widget.data.variation1Options.add(trimmed);
      _opt1Input.clear();
      _rebuild();
    });
  }

  void _removeOption1(String val) {
    setState(() {
      widget.data.variation1Options.remove(val);
      _rebuild();
    });
  }

  void _addOption2(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty || widget.data.variation2Options.contains(trimmed)) return;
    setState(() {
      widget.data.variation2Options.add(trimmed);
      _opt2Input.clear();
      _rebuild();
    });
  }

  void _removeOption2(String val) {
    setState(() {
      widget.data.variation2Options.remove(val);
      _rebuild();
    });
  }

  void _rebuild() {
    widget.data.rebuildMatrix(
      defaultPrice: double.tryParse(_batchPrice.text) ?? widget.initialSellingPrice,
      defaultCost: double.tryParse(_batchCost.text) ?? widget.initialCostPrice,
      defaultStock: int.tryParse(_batchStock.text) ?? widget.initialStock,
    );
    widget.onChanged();
  }

  void _applyBatch() {
    final p = double.tryParse(_batchPrice.text);
    final c = double.tryParse(_batchCost.text);
    final s = int.tryParse(_batchStock.text);
    setState(() {
      for (final v in widget.data.variants) {
        if (p != null) v.sellingPrice = p;
        if (c != null) v.costPrice = c;
        if (s != null) v.stockQty = s;
      }
    });
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Applied to all variants!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tier 1 Variation (Manual Input) ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Variation 1',
                      style: AppTextStyles.labelCaps.copyWith(color: primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _v1NameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Variation Type Name',
                        hintText: 'e.g. Color, Size, Capacity, Model',
                        isDense: true,
                      ),
                      onChanged: (v) {
                        widget.data.variation1Name = v;
                        widget.onChanged();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Enter an option name (e.g. Red, 800ml, Small) and tap "+ Add" to create your product options.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),

              // Active selected tags
              if (widget.data.variation1Options.isNotEmpty) ...[
                Text(
                  'Added Options (${widget.data.variation1Options.length}):',
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final opt in widget.data.variation1Options)
                      Chip(
                        label: Text(opt, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeOption1(opt),
                        backgroundColor: primary.withValues(alpha: 0.12),
                        side: BorderSide(color: primary.withValues(alpha: 0.4)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Custom input field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _opt1Input,
                      decoration: InputDecoration(
                        labelText: 'Option Value',
                        hintText: 'Type option and tap Add (e.g. Black, 800ml)',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onSubmitted: _addOption1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _addOption1(_opt1Input.text),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Tier 2 Variation (Optional Manual Input) ──
        if (!_enableTier2)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _enableTier2 = true;
                  if (widget.data.variation2Name.trim().isEmpty) {
                    widget.data.variation2Name = 'Variation 2';
                    _v2NameCtrl.text = 'Variation 2';
                  }
                });
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('+ Add Second Variation (e.g. Size, Specification)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Variation 2',
                        style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _v2NameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Variation 2 Type Name',
                          hintText: 'e.g. Size, Model, Specification',
                          isDense: true,
                        ),
                        onChanged: (v) {
                          widget.data.variation2Name = v;
                          widget.onChanged();
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                      tooltip: 'Remove Variation 2',
                      onPressed: () {
                        setState(() {
                          _enableTier2 = false;
                          widget.data.variation2Options.clear();
                          _rebuild();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Combine a 2nd attribute (e.g. Size) to generate multi-dimensional combinations (e.g. Color × Size).',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),

                // Active selected tags for Tier 2
                if (widget.data.variation2Options.isNotEmpty) ...[
                  Text(
                    'Added Options (${widget.data.variation2Options.length}):',
                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final opt in widget.data.variation2Options)
                        Chip(
                          label: Text(opt, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeOption2(opt),
                          backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Custom input field for Tier 2
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _opt2Input,
                        decoration: InputDecoration(
                          labelText: 'Option Value',
                          hintText: 'Type option and tap Add (e.g. Large, 1 Liter)',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onSubmitted: _addOption2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _addOption2(_opt2Input.text),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        if (widget.data.variants.isEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 22, color: primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How variations work',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1. Enter a variation type name (e.g. Color, Size, or Volume).\n'
                        '2. Type each option value above and tap "+ Add" or press Enter.\n'
                        '3. Each option generates a row below where you can set individual prices, cost, stock, barcodes, and SKUs.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 20),

          // ── Batch Quick Apply Section ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: AppColors.expense, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Batch Apply to All (${widget.data.variants.length} Combinations)',
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _batchPrice,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price (₱)',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _batchCost,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Cost (₱)',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _batchStock,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyBatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Generated Variants Matrix List ──
          Text(
            'Combinations & Inventory (${widget.data.variants.length})',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),

          for (int i = 0; i < widget.data.variants.length; i++)
            _VariantRowCard(
              key: ValueKey(widget.data.variants[i].uid),
              variant: widget.data.variants[i],
              onChanged: widget.onChanged,
            ),
        ],
      ],
    );
  }
}

class _VariantRowCard extends StatefulWidget {
  const _VariantRowCard({
    super.key,
    required this.variant,
    required this.onChanged,
  });

  final ProductVariant variant;
  final VoidCallback onChanged;

  @override
  State<_VariantRowCard> createState() => _VariantRowCardState();
}

class _VariantRowCardState extends State<_VariantRowCard> {
  late TextEditingController _priceCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _partNumberCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: widget.variant.sellingPrice > 0 ? widget.variant.sellingPrice.toString() : '');
    _costCtrl = TextEditingController(text: widget.variant.costPrice > 0 ? widget.variant.costPrice.toString() : '');
    _stockCtrl = TextEditingController(text: widget.variant.stockQty.toString());
    _skuCtrl = TextEditingController(text: widget.variant.sku ?? '');
    _barcodeCtrl = TextEditingController(text: widget.variant.barcode ?? '');
    _partNumberCtrl = TextEditingController(text: widget.variant.partNumber ?? '');
  }

  @override
  void didUpdateWidget(covariant _VariantRowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variant != oldWidget.variant) {
      _priceCtrl.text = widget.variant.sellingPrice > 0 ? widget.variant.sellingPrice.toString() : '';
      _costCtrl.text = widget.variant.costPrice > 0 ? widget.variant.costPrice.toString() : '';
      _stockCtrl.text = widget.variant.stockQty.toString();
      _skuCtrl.text = widget.variant.sku ?? '';
      _barcodeCtrl.text = widget.variant.barcode ?? '';
      _partNumberCtrl.text = widget.variant.partNumber ?? '';
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _partNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.variant.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primary,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Stock: ${widget.variant.stockQty}',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.variant.stockQty > 0 ? AppColors.active : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price (₱)',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    widget.variant.sellingPrice = double.tryParse(v) ?? 0;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _costCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cost (₱)',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    widget.variant.costPrice = double.tryParse(v) ?? 0;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock Qty',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    widget.variant.stockQty = int.tryParse(v) ?? 0;
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skuCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Variant SKU (e.g. SH-10W40-1L)',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    widget.variant.sku = v.trim().isEmpty ? null : v.trim();
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _partNumberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Part Number',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    widget.variant.partNumber = v.trim().isEmpty ? null : v.trim();
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _barcodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Barcode (Optional)',
                    hintText: 'Scannable barcode',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    widget.variant.barcode = v.trim().isEmpty ? null : v.trim();
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                tooltip: 'Scan barcode',
                onPressed: () async {
                  final scanned = await scanBarcode(context);
                  if (scanned != null && context.mounted) {
                    _barcodeCtrl.text = scanned;
                    widget.variant.barcode = scanned;
                    widget.onChanged();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
