import 'package:flutter/material.dart';
import '../../../core/services/vision/product_vision_models.dart';
import '../../../core/services/vision/product_vision_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_image.dart';

/// Modal dialog / sheet that previews extracted product information from
/// a captured motorcycle part photo or label and allows fast fine-tuning before auto-filling.
class ProductVisionDialog extends StatefulWidget {
  final ProductVisionResult initialResult;
  final List<String> availableCategories;

  const ProductVisionDialog({
    super.key,
    required this.initialResult,
    required this.availableCategories,
  });

  static Future<ProductVisionResult?> show(
    BuildContext context, {
    required ProductVisionResult initialResult,
    required List<String> availableCategories,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    if (isDesktop) {
      return showDialog<ProductVisionResult>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 760),
            child: ProductVisionDialog(
              initialResult: initialResult,
              availableCategories: availableCategories,
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<ProductVisionResult>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: AppColors.bgSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.90,
          child: ProductVisionDialog(
            initialResult: initialResult,
            availableCategories: availableCategories,
          ),
        ),
      );
    }
  }

  @override
  State<ProductVisionDialog> createState() => _ProductVisionDialogState();
}

class _ProductVisionDialogState extends State<ProductVisionDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _partNumberController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _descriptionController;
  String? _selectedCategory;

  static const List<String> _popularBrands = [
    'Honda',
    'Yamaha',
    'Motul',
    'Repsol',
    'Brembo',
    'RCB',
    'NGK',
    'FDR',
    'Castrol',
    'Koso',
    'Suzuki',
    'Kawasaki',
  ];

  static const List<String> _popularPartTypes = [
    'Engine Oil',
    'Brake Pads',
    'Spark Plug',
    'V-Belt',
    'Drive Chain',
    'Shock Absorber',
    'Tubeless Tire',
    'Battery',
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.initialResult;
    _nameController = TextEditingController(text: r.name ?? '');
    _brandController = TextEditingController(text: r.brand ?? '');
    _partNumberController = TextEditingController(text: r.partNumber ?? '');
    _barcodeController = TextEditingController(text: r.barcode ?? '');
    _sellingPriceController = TextEditingController(
      text: (r.sellingPrice != null && r.sellingPrice! > 0)
          ? r.sellingPrice.toString()
          : '',
    );
    _costPriceController = TextEditingController(
      text: (r.costPrice != null && r.costPrice! > 0)
          ? r.costPrice.toString()
          : '',
    );
    _descriptionController = TextEditingController(
      text: (r.description != null && r.description!.isNotEmpty)
          ? r.description!
          : (r.rawText ?? ''),
    );

    if (r.category != null && widget.availableCategories.contains(r.category)) {
      _selectedCategory = r.category;
    } else if (widget.availableCategories.isNotEmpty) {
      _selectedCategory = widget.availableCategories.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _partNumberController.dispose();
    _barcodeController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyBrandTag(String brand) {
    setState(() {
      _brandController.text = brand;
      // Re-run parser with brand tag
      final reparse = ProductVisionService.parseText(
        '$brand ${_nameController.text}',
        availableCategories: widget.availableCategories,
      );
      if (reparse.category != null && widget.availableCategories.contains(reparse.category)) {
        _selectedCategory = reparse.category;
      }
      if (!_nameController.text.toLowerCase().contains(brand.toLowerCase())) {
        _nameController.text = '$brand ${_nameController.text}'.trim();
      }
    });
  }

  void _applyPartTypeTag(String partType) {
    setState(() {
      final brand = _brandController.text.trim();
      final newName = brand.isNotEmpty ? '$brand $partType' : partType;
      _nameController.text = newName;

      final reparse = ProductVisionService.parseText(
        partType,
        availableCategories: widget.availableCategories,
      );
      if (reparse.category != null && widget.availableCategories.contains(reparse.category)) {
        _selectedCategory = reparse.category;
      }
    });
  }

  void _apply() {
    final result = widget.initialResult.copyWith(
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      partNumber: _partNumberController.text.trim().isEmpty ? null : _partNumberController.text.trim(),
      category: _selectedCategory,
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      sellingPrice: double.tryParse(_sellingPriceController.text.trim()) ?? 0.0,
      costPrice: double.tryParse(_costPriceController.text.trim()) ?? 0.0,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    final hasBarcode = _barcodeController.text.trim().isNotEmpty;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = bottomInset > 0
        ? bottomInset + 12
        : (MediaQuery.paddingOf(context).bottom + 12);

    return Column(
      children: [
        // Drag handle on mobile
        if (!isDesktop) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.active.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: AppColors.active,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Vision Product Auto-Fill',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Review scanned photo details and tap to auto-fill form',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // Scrollable Form Details
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            children: [
              // Scanned Image Preview Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: AppImage(
                          imagePath: widget.initialResult.imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.active.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.active.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome, size: 12, color: AppColors.active),
                                    SizedBox(width: 4),
                                    Text(
                                      'PHOTO SCANNED',
                                      style: TextStyle(
                                        color: AppColors.active,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasBarcode) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                                  ),
                                  child: const Text(
                                    'BARCODE FOUND',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasBarcode
                                ? 'Barcode & OCR details detected: ${_barcodeController.text}'
                                : 'AI OCR & Packaging Details Extracted',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Confidence: ${(widget.initialResult.confidence * 100).clamp(50, 99).toInt()}% • Details extraction only (not saved as photo)',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Tag Helpers
              const Text(
                'ONE-TAP MOTORCYCLE BRANDS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _popularBrands.map((brand) {
                    final selected = _brandController.text.trim().toLowerCase() == brand.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(
                          brand,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        backgroundColor: selected ? AppColors.accent : AppColors.bgSurface2,
                        side: BorderSide(
                          color: selected ? AppColors.accent : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onPressed: () => _applyBrandTag(brand),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'ONE-TAP PART TYPES',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _popularPartTypes.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(
                          type,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: AppColors.bgSurface2,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onPressed: () => _applyPartTypeTag(type),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Product Name
              _buildField(
                label: 'PRODUCT NAME',
                controller: _nameController,
                hint: 'e.g. Motul 7100 4T 10W-40 1L',
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 12),

              // Brand & Part Number Row
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'BRAND',
                      controller: _brandController,
                      hint: 'e.g. Motul, Honda, RCB',
                      icon: Icons.branding_watermark_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      label: 'PART NUMBER',
                      controller: _partNumberController,
                      hint: 'e.g. 06455-KRE-G01',
                      icon: Icons.tag_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category Dropdown
              if (widget.availableCategories.isNotEmpty) ...[
                const Text(
                  'CATEGORY',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      dropdownColor: AppColors.bgSurface,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                      items: widget.availableCategories.map((c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(
                            c,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Barcode
              _buildField(
                label: 'BARCODE / SKU',
                controller: _barcodeController,
                hint: 'e.g. 3374650247651',
                icon: Icons.qr_code_rounded,
              ),
              const SizedBox(height: 12),

              // Selling Price & Cost Price
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'SELLING PRICE (₱)',
                      controller: _sellingPriceController,
                      hint: '0.00',
                      icon: Icons.payments_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      label: 'COST / CAPITAL (₱)',
                      controller: _costPriceController,
                      hint: '0.00',
                      icon: Icons.account_balance_wallet_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Action Buttons
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
          decoration: const BoxDecoration(
            color: AppColors.bgSurface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text(
                    'AUTO-FILL FORM',
                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 16, color: AppColors.textSecondary),
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
