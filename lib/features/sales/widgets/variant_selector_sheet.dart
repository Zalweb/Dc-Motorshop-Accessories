import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/tactile_button.dart';

class VariantSelectionResult {
  const VariantSelectionResult({
    required this.variant,
    required this.quantity,
  });

  final ProductVariant variant;
  final int quantity;
}

Future<VariantSelectionResult?> showVariantSelectorSheet({
  required BuildContext context,
  required Product product,
}) {
  return showModalBottomSheet<VariantSelectionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _VariantSelectorSheet(product: product),
  );
}

class _VariantSelectorSheet extends ConsumerStatefulWidget {
  const _VariantSelectorSheet({required this.product});

  final Product product;

  @override
  ConsumerState<_VariantSelectorSheet> createState() => _VariantSelectorSheetState();
}

class _VariantSelectorSheetState extends ConsumerState<_VariantSelectorSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  String? _selectedOpt1;
  String? _selectedOpt2;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _enterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterAnim,
        curve: Curves.easeOutBack,
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterAnim,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterAnim,
        curve: Curves.easeOut,
      ),
    );

    _enterAnim.forward();

    // Default to the first available variant options
    if (widget.product.variants.isNotEmpty) {
      final first = widget.product.variants.first;
      _selectedOpt1 = _getVariantOpt1(first);
      _selectedOpt2 = first.option2;
    }
  }

  @override
  void dispose() {
    _enterAnim.dispose();
    super.dispose();
  }

  String? _getVariantOpt1(ProductVariant v) {
    if (v.option1 != null && v.option1!.trim().isNotEmpty) {
      return v.option1!.trim();
    }
    if (v.name.trim().isNotEmpty) {
      return v.name.trim();
    }
    return null;
  }

  ProductVariant? get _matchedVariant {
    for (final v in widget.product.variants) {
      final opt1 = _getVariantOpt1(v);
      final match1 = opt1 == _selectedOpt1;
      final match2 = v.option2 == _selectedOpt2;
      if (match1 && match2) return v;
    }
    return widget.product.variants.firstOrNull;
  }

  List<String> get _opt1List {
    final list = <String>[];
    for (final v in widget.product.variants) {
      final opt1 = _getVariantOpt1(v);
      if (opt1 != null && !list.contains(opt1)) {
        list.add(opt1);
      }
    }
    return list;
  }

  List<String> get _opt2List {
    final list = <String>[];
    for (final v in widget.product.variants) {
      if (v.option2 != null && !list.contains(v.option2)) {
        list.add(v.option2!);
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final allowOversell = ref.watch(businessSettingsStreamProvider).value?.allowSellWhenOutOfStock ?? false;
    final variant = _matchedVariant;
    final stock = variant?.stockQty ?? 0;
    final price = variant?.sellingPrice ?? widget.product.sellingPrice;
    final isOutOfStock = !widget.product.isService && stock <= 0 && !allowOversell;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header summary: Image, Title, Price, Stock
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppImage(
                      imageUrl: widget.product.imageUrl,
                      imagePath: widget.product.imagePath,
                      width: 72,
                      height: 72,
                      borderRadius: BorderRadius.circular(12),
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.inventory_2_outlined,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatPeso(price),
                            style: AppTextStyles.headingMedium.copyWith(
                              color: primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOutOfStock ? 'Out of stock' : 'Stock: $stock available',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isOutOfStock ? AppColors.danger : (stock <= 5 ? AppColors.expense : AppColors.active),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 28),

                // Variation 1 options
                if (_opt1List.isNotEmpty) ...[
                  Text(
                    widget.product.variation1Name?.isNotEmpty == true
                        ? widget.product.variation1Name!
                        : 'MODEL',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final opt in _opt1List)
                        TactileButton(
                          scaleDown: 0.90,
                          hoverScale: 1.08,
                          child: ChoiceChip(
                            label: Text(opt),
                            selected: _selectedOpt1 == opt,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedOpt1 = opt;
                                  _quantity = 1;
                                });
                              }
                            },
                            selectedColor: primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: _selectedOpt1 == opt ? primary : theme.colorScheme.onSurface,
                              fontWeight: _selectedOpt1 == opt ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: _selectedOpt1 == opt ? primary : theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Variation 2 options
                if (_opt2List.isNotEmpty) ...[
                  Text(
                    widget.product.variation2Name ?? 'Option 2',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final opt in _opt2List)
                        TactileButton(
                          scaleDown: 0.90,
                          hoverScale: 1.08,
                          child: ChoiceChip(
                            label: Text(opt),
                            selected: _selectedOpt2 == opt,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedOpt2 = opt;
                                  _quantity = 1;
                                });
                              }
                            },
                            selectedColor: AppColors.accent.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: _selectedOpt2 == opt ? AppColors.accent : theme.colorScheme.onSurface,
                              fontWeight: _selectedOpt2 == opt ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: _selectedOpt2 == opt ? AppColors.accent : theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Quantity Stepper
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quantity',
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          TactileButton(
                            scaleDown: 0.85,
                            hoverScale: 1.15,
                            child: IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$_quantity',
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          TactileButton(
                            scaleDown: 0.85,
                            hoverScale: 1.15,
                            child: IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: (!allowOversell && _quantity >= stock)
                                  ? null
                                  : () => setState(() => _quantity++),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Add to Cart Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TactileButton(
                    enabled: !isOutOfStock && variant != null,
                    scaleDown: 0.94,
                    hoverScale: 1.02,
                    child: FilledButton(
                      onPressed: isOutOfStock || variant == null
                          ? null
                          : () {
                              Navigator.of(context).pop(
                                VariantSelectionResult(
                                  variant: variant,
                                  quantity: _quantity,
                                ),
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isOutOfStock
                            ? 'Out of Stock'
                            : 'Add to Cart • ${formatPeso(price * _quantity)}',
                        style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
