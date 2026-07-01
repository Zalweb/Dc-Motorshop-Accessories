import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/barcode_scanner_screen.dart';
import '../../shared/widgets/glass_container.dart';

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
    } else if (widget.initialBarcode != null) {
      _barcode.text = widget.initialBarcode!;
    }
  }
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _partNumber = TextEditingController();
  final _brand = TextEditingController();
  final _cost = TextEditingController(text: '0');
  final _selling = TextEditingController(text: '0');
  final _stock = TextEditingController(text: '0');

  String? _category;
  bool _isService = false;
  String? _imagePath;
  bool _saving = false;

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

  Future<void> _scan() async {
    final code = await scanBarcode(context);
    if (code != null) _barcode.text = code;
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

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
      ..costPrice = double.tryParse(_cost.text) ?? 0
      ..sellingPrice = double.tryParse(_selling.text) ?? 0
      ..stockQty = _isService ? 0 : (int.tryParse(_stock.text) ?? 0)
      ..imagePath = _imagePath;

    if (widget.stage) {
      if (!mounted) return;
      context.pop(product);
      return;
    }

    await ref.read(productRepositoryProvider).save(product);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListStreamProvider).value ?? [];
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editProduct != null ? 'Edit Product' : 'Add Product'),
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
            // Image + core details.
            _FormCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: _ImageBox(imagePath: _imagePath),
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

    if (imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(File(imagePath!),
            width: 110, height: 110, fit: BoxFit.cover),
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
          value: value,
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

