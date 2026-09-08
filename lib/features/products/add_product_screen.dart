import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/barcode_scanner_screen.dart';
import '../../shared/widgets/glass_container.dart';
import 'manage_variants_screen.dart';
import 'widgets/variant_builder_widget.dart';
import '../../core/services/vision/product_vision_service.dart';
import 'widgets/product_vision_dialog.dart';

/// Navigation payload for the Add Product route.
class AddProductArgs {
  const AddProductArgs({this.initialBarcode, this.stage = false, this.editProduct});

  /// Prefilled barcode when arriving from Bulk Add's "new product" flow.
  final String? initialBarcode;

  /// When true, the form returns the built [Product] instead of saving it,
  /// so the caller (Bulk Add) can queue it for a single confirm step.
  final bool stage;

  /// When set, the form edits this product in place instead of creating one.
  final Product? editProduct;
}

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({
    super.key,
    this.initialBarcode,
    this.stage = false,
    this.editProduct,
  });

  /// Prefilled barcode when arriving from Bulk Add's "new product" flow.
  final String? initialBarcode;

  /// When true, [_save] pops with the built [Product] instead of persisting it.
  final bool stage;

  /// When set, [_save] updates this product instead of inserting a new one.
  final Product? editProduct;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcode = TextEditingController();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _partNumber = TextEditingController();
  final _brand = TextEditingController();
  final _cost = TextEditingController(text: '0');
  final _selling = TextEditingController(text: '0');
  final _stock = TextEditingController(text: '0');

  late VariantBuilderData _variantData;
  String? _category;
  bool _isService = false;
  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.editProduct;
    if (edit != null) {
      _name.text = edit.name;
      _barcode.text = edit.barcode ?? '';
      _description.text = edit.description ?? '';
      _partNumber.text = edit.partNumber ?? '';
      _brand.text = edit.brand ?? '';
      _cost.text = edit.costPrice.toString();
      _selling.text = edit.sellingPrice.toString();
      _stock.text = edit.stockQty.toString();
      _category = edit.category;
      _isService = edit.isService;
      _imagePath = edit.imagePath;

      final v1List = <String>[];
      final v2List = <String>[];
      for (final v in edit.variants) {
        if (v.option1 != null && !v1List.contains(v.option1)) v1List.add(v.option1!);
        if (v.option2 != null && !v2List.contains(v.option2)) v2List.add(v.option2!);
      }

      _variantData = VariantBuilderData(
        hasVariants: edit.hasVariants,
        variation1Name: edit.variation1Name ?? 'Color',
        variation1Options: v1List,
        variation2Name: edit.variation2Name ?? 'Size',
        variation2Options: v2List,
        variants: edit.variants
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
    } else {
      _variantData = VariantBuilderData();
      if (widget.initialBarcode != null) {
        _barcode.text = widget.initialBarcode!;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _barcode,
      _name,
      _description,
      _partNumber,
      _brand,
      _cost,
      _selling,
      _stock,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _bumpStock(int delta) {
    final current = int.tryParse(_stock.text) ?? 0;
    _stock.text = (current + delta).clamp(0, 1 << 31).toString();
  }

  void _toggleVariants(bool val) {
    setState(() {
      _variantData.hasVariants = val;
      if (val) {
        if (_variantData.variation1Name.trim().isEmpty) {
          _variantData.variation1Name = 'Color';
        }
        _variantData.rebuildMatrix(
          defaultPrice: double.tryParse(_selling.text) ?? 0,
          defaultCost: double.tryParse(_cost.text) ?? 0,
          defaultStock: int.tryParse(_stock.text) ?? 0,
        );
      } else {
        _variantData.variants.clear();
        _variantData.variation1Options.clear();
        _variantData.variation2Options.clear();
      }
    });
  }

  Future<void> _scan() async {
    final code = await scanBarcode(context);
    if (code != null) _barcode.text = code;
  }

  Future<void> _scanProductVision({ImageSource? source}) async {
    final chosenSource = source ??
        await showModalBottomSheet<ImageSource>(
          context: context,
          useRootNavigator: true,
          backgroundColor: AppColors.bgSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      'AI Vision Product Auto-Fill',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Text(
                      'Take a photo of motorcycle part or label to auto-fill details',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: AppColors.accent),
                    ),
                    title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Snap packaging, label, or motorcycle part', style: TextStyle(fontSize: 11)),
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.active.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_library_rounded, color: AppColors.active),
                    ),
                    title: const Text('Choose from Gallery / Files', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Pick existing photo from device', style: TextStyle(fontSize: 11)),
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),
        );

    if (chosenSource == null) return;

    try {
      final file = await ImagePicker().pickImage(
        source: chosenSource,
        imageQuality: 85,
      );
      if (file == null) return;

      if (!mounted) return;

      // Show analysis progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    SizedBox(width: 16),
                    Text('Scanning motorcycle part with AI...'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final categories = ref.read(categoryListStreamProvider).value?.map((c) => c.name).toList() ?? [];
      final existingProducts = ref.read(productListStreamProvider).value;
      final visionResult = await ProductVisionService.parseImage(
        file,
        availableCategories: categories,
        existingProducts: existingProducts,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      // Show interactive confirmation sheet
      final confirmed = await ProductVisionDialog.show(
        context,
        initialResult: visionResult,
        availableCategories: categories,
      );

      if (confirmed != null && mounted) {
        setState(() {
          if (confirmed.name != null && confirmed.name!.isNotEmpty) {
            _name.text = confirmed.name!;
          }
          if (confirmed.brand != null && confirmed.brand!.isNotEmpty) {
            _brand.text = confirmed.brand!;
          }
          if (confirmed.partNumber != null && confirmed.partNumber!.isNotEmpty) {
            _partNumber.text = confirmed.partNumber!;
          }
          if (confirmed.category != null && confirmed.category!.isNotEmpty) {
            _category = confirmed.category;
          }
          if (confirmed.barcode != null && confirmed.barcode!.isNotEmpty) {
            _barcode.text = confirmed.barcode!;
          }
          if (confirmed.sellingPrice != null && confirmed.sellingPrice! > 0) {
            _selling.text = confirmed.sellingPrice.toString();
          }
          if (confirmed.costPrice != null && confirmed.costPrice! > 0) {
            _cost.text = confirmed.costPrice.toString();
          }
          if (confirmed.description != null && confirmed.description!.isNotEmpty) {
            _description.text = confirmed.description!;
          }
          if (confirmed.imagePath != null && confirmed.imagePath!.isNotEmpty) {
            _imagePath = confirmed.imagePath;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Auto-filled "${_name.text}" from scanned photo!'),
                ),
              ],
            ),
            backgroundColor: AppColors.active,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vision scan failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final isNew = widget.editProduct == null;
    final hasVariants = !_isService && _variantData.hasVariants && _variantData.variants.isNotEmpty;

    final product = (widget.editProduct ?? Product())
      ..name = _name.text.trim()
      ..barcode = _barcode.text.trim().isEmpty ? null : _barcode.text.trim()
      ..category = _category
      ..description =
          _description.text.trim().isEmpty ? null : _description.text.trim()
      ..partNumber =
          _partNumber.text.trim().isEmpty ? null : _partNumber.text.trim()
      ..brand = _brand.text.trim().isEmpty ? null : _brand.text.trim()
      ..isService = _isService
      ..hasVariants = hasVariants
      ..variation1Name = hasVariants ? _variantData.variation1Name : null
      ..variation2Name = (hasVariants && _variantData.variation2Options.isNotEmpty)
          ? _variantData.variation2Name
          : null
      ..variants = hasVariants ? _variantData.variants : []
      ..costPrice = hasVariants
          ? (_variantData.variants.firstOrNull?.costPrice ?? 0)
          : (double.tryParse(_cost.text) ?? 0)
      ..sellingPrice = hasVariants
          ? (_variantData.variants.firstOrNull?.sellingPrice ?? 0)
          : (double.tryParse(_selling.text) ?? 0)
      ..stockQty = _isService
          ? 0
          : (hasVariants
              ? _variantData.variants.fold(0, (sum, v) => sum + v.stockQty)
              : (int.tryParse(_stock.text) ?? 0))
      ..imagePath = _imagePath;

    if (widget.stage) {
      if (!mounted) return;
      context.pop(product);
      return;
    }

    await ref.read(productRepositoryProvider).save(product);
    if (!mounted) return;

    // Next suggestion prompt when adding a new physical product without variants
    if (isNew && !hasVariants && !_isService) {
      setState(() => _saving = false);
      final addNow = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.active, size: 24),
              SizedBox(width: 10),
              Text('Product Added!'),
            ],
          ),
          content: Text(
            'Would you like to add Shopee-style variations (colors, sizes, or models) for "${product.name}"?',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No, Finish'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.style_outlined, size: 18),
              label: const Text('+ Add Variations'),
            ),
          ],
        ),
      );

      if (addNow == true && mounted) {
        final result = await Navigator.of(context).push<VariantBuilderData>(
          MaterialPageRoute(
            builder: (_) => ManageVariantsScreen(
              initialData: VariantBuilderData(),
              productName: product.name,
              defaultCostPrice: product.costPrice,
              defaultSellingPrice: product.sellingPrice,
              defaultStock: product.stockQty,
            ),
          ),
        );
        if (result != null && result.hasVariants && result.variants.isNotEmpty) {
          product
            ..hasVariants = true
            ..variation1Name = result.variation1Name
            ..variation2Name = result.variation2Options.isNotEmpty ? result.variation2Name : null
            ..variants = result.variants
            ..stockQty = result.variants.fold(0, (sum, v) => sum + v.stockQty);
          await ref.read(productRepositoryProvider).save(product);
        }
      }
    }

    if (!mounted) return;
    context.pop();
  }

  Future<void> _deleteProduct() async {
    final edit = widget.editProduct;
    if (edit == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text(
          'Are you sure you want to delete "${edit.name}"? '
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

    if (confirmed == true && mounted) {
      await ref.read(productRepositoryProvider).delete(edit.uid);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${edit.name}"')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListStreamProvider).value ?? [];
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editProduct != null ? 'Edit Product' : 'Add Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded, color: AppColors.accent),
            tooltip: 'AI Vision Auto-Fill',
            onPressed: () => _scanProductVision(),
          ),
          if (widget.editProduct != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              tooltip: 'Delete Product',
              onPressed: _deleteProduct,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Theme.of(context).colorScheme.onPrimary),
                  )
                : Text(widget.editProduct != null
                    ? 'SAVE CHANGES'
                    : widget.stage
                        ? 'ADD TO LIST'
                        : 'ADD PRODUCT'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // Image + core details + Vision Auto-Fill CTA
            _FormCard(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _scanProductVision(),
                        child: Stack(
                          children: [
                            _ImageBox(imagePath: _imagePath),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _LabeledField(
                              label: 'Product Name',
                              required: true,
                              controller: _name,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _CategoryDropdown(
                              categories: categories.map((c) => c.name).toList(),
                              value: _category,
                              onChanged: (v) => setState(() => _category = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Dedicated AI Vision Auto-Fill Button
                  InkWell(
                    onTap: () => _scanProductVision(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text(
                            'Scan Part Photo to Auto-Fill Details',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _FormCard(
              title: 'Barcode',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _barcode,
                      decoration:
                          const InputDecoration(hintText: 'Enter barcode'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: _scan,
                    icon: const Icon(Icons.qr_code_scanner),
                    style: IconButton.styleFrom(
                      backgroundColor: primary,
                      minimumSize: const Size(56, 56),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _FormCard(
              title: 'Specifications',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                            label: 'Part number', controller: _partNumber),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            _LabeledField(label: 'Brand', controller: _brand),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                      label: 'Description',
                      controller: _description,
                      maxLines: 3),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Service toggle.
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(20),
              child: SwitchListTile(
                value: _isService,
                onChanged: (v) => setState(() => _isService = v),
                title: Text('This is a service', style: AppTextStyles.body),
                subtitle: Text('Services do not track stock',
                    style: AppTextStyles.bodySmall),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: primary,
              ),
            ),
            const SizedBox(height: 16),

            // Shopee-style Variations Card
            if (!_isService) ...[
              _FormCard(
                title: 'Product Variations',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _toggleVariants(!_variantData.hasVariants),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.style_outlined, color: primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Enable Variations (Shopee-Style)',
                                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    _variantData.hasVariants
                                        ? 'Color, Model, Size matrix with individual stock.'
                                        : 'Sell as a single item with 1 price & stock.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _variantData.hasVariants,
                              activeThumbColor: primary,
                              onChanged: _toggleVariants,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_variantData.hasVariants) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      VariantBuilderWidget(
                        data: _variantData,
                        initialCostPrice: double.tryParse(_cost.text) ?? 0,
                        initialSellingPrice: double.tryParse(_selling.text) ?? 0,
                        initialStock: int.tryParse(_stock.text) ?? 0,
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pricing & Stock (shown when no variants are active)
            if (!_variantData.hasVariants) ...[
              _FormCard(
                title: 'Pricing',
                child: Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Cost price (₱)',
                        controller: _cost,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: 'Selling price (₱)',
                        required: true,
                        controller: _selling,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                            ? 'Enter a price'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              if (!_isService) ...[
                const SizedBox(height: 16),
                _FormCard(
                  title: 'Inventory',
                  child: Column(
                    children: [
                      _LabeledField(
                        label: 'Stock quantity',
                        controller: _stock,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 14),
                      _QuickQtyChips(onBump: _bumpStock),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Groups a form section inside a glassmorphic card with an optional caps title.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: AppTextStyles.labelCaps
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _ImageBox extends StatelessWidget {
  const _ImageBox({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (imagePath != null && imagePath!.isNotEmpty) {
      return AppImage(
        imagePath: imagePath,
        imageUrl: imagePath,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(20),
      );
    }
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_rounded, color: primary, size: 28),
          const SizedBox(height: 6),
          Text(
            'Photo',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
            if (required)
              const Text(' *', style: TextStyle(color: AppColors.danger)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
        ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<String> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          hint: Text(
            'Select category',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _QuickQtyChips extends StatelessWidget {
  const _QuickQtyChips({required this.onBump});

  final ValueChanged<int> onBump;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const deltas = [-1, 1, 5, 10, 50, 100];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: deltas.map((d) {
        return ActionChip(
          label: Text(d < 0 ? '$d' : '+$d'),
          onPressed: () => onBump(d),
          backgroundColor: theme.colorScheme.surfaceContainer,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }).toList(),
    );
  }
}

