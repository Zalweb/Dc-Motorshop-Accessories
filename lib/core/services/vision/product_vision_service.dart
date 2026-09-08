import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/models/product.dart';
import 'product_vision_models.dart';

/// Service responsible for scanning motorcycle parts & product labels,
/// extracting part numbers, brands, categories, prices, and barcodes.
class ProductVisionService {
  static const List<String> knownBrands = [
    'Motul',
    'Castrol',
    'Repsol',
    'Yamalube',
    'Shell Advance',
    'Pertua',
    'Mobil 1',
    'Liqui Moly',
    'Kixx',
    'Top 1',
    'Honda',
    'Yamaha',
    'Kawasaki',
    'Suzuki',
    'Brembo',
    'Racing Boy',
    'RCB',
    'Nissin',
    'Koso',
    'Uma Racing',
    'Akrapovic',
    'Yoshimura',
    'Mutarru',
    'JRP',
    'Domino',
    'FDR',
    'Maxxis',
    'Quick',
    'IRC',
    'Pirelli',
    'Michelin',
    'Dunlop',
    'Swallow',
    'CST',
    'NGK',
    'Denso',
    'Bosch',
    'Osram',
    'Ohlins',
    'Showa',
    'KYB',
    'YSS',
    'TGR',
    'Spyker',
    'Yuasa',
    'Motolite',
    'DID',
    'SSS',
    'RK Takasago',
    'Bando',
    'Gates',
    'RS8',
    'Spec V',
    'SEC',
    'Givi',
    'Shad',
    'Evo',
    'HJC',
    'KYT',
    'Spyder',
  ];

  /// Common motorcycle part types for fast recognition and auto-categorization.
  static const List<String> commonPartTypes = [
    'Engine Oil',
    'Brake Pads',
    'Brake Shoe',
    'Spark Plug',
    'V-Belt',
    'Drive Chain',
    'Sprocket Set',
    'Shock Absorber',
    'Tubeless Tire',
    'Inner Tube',
    'Side Mirror',
    'Brake Caliper',
    'Brake Lever',
    'Carburetor',
    'Battery',
    'Fork Oil',
    'Coolant',
    'Air Filter',
    'Flyball Roller',
    'Clutch Lining',
  ];

  /// Analyzes the captured or selected image [file] and returns a populated [ProductVisionResult].
  static Future<ProductVisionResult> parseImage(
    XFile file, {
    List<String>? availableCategories,
    List<Product>? existingProducts,
    String? hintText,
  }) async {
    final bytes = await file.readAsBytes();

    // Universal platform-safe display path: on web use data url, on native use path
    final displayPath = kIsWeb
        ? 'data:image/jpeg;base64,${base64Encode(bytes)}'
        : file.path;

    // 1. Try barcode detection from image
    String? detectedBarcode;
    if (!kIsWeb) {
      try {
        final scanner = MobileScannerController();
        final capture = await scanner.analyzeImage(file.path);
        await scanner.dispose();
        if (capture != null && capture.barcodes.isNotEmpty) {
          detectedBarcode = capture.barcodes.first.rawValue;
        }
      } catch (e) {
        debugPrint('ProductVision barcode scanner error: $e');
      }
    }

    // 2. If barcode matches an existing shop product, auto-fill from that product!
    if (detectedBarcode != null &&
        detectedBarcode.isNotEmpty &&
        existingProducts != null) {
      for (final p in existingProducts) {
        if (p.barcode != null && p.barcode == detectedBarcode) {
          return ProductVisionResult(
            name: p.name,
            brand: p.brand,
            partNumber: p.partNumber,
            category: p.category,
            sellingPrice: p.sellingPrice,
            costPrice: p.costPrice,
            barcode: p.barcode,
            description: p.description,
            imagePath: displayPath,
            rawText: 'Matched existing product: ${p.name}',
            confidence: 0.98,
          );
        }
      }
    }

    // 3. Synthesize text source from filename (filtering out generic camera prefixes),
    // user hint, and detected barcode
    final filenameClean = _cleanFilename(file.name);

    final combinedText = [
      hintText ?? '',
      filenameClean,
      if (detectedBarcode != null) 'Barcode: $detectedBarcode',
    ].where((s) => s.trim().isNotEmpty).join(' ');

    return parseText(
      combinedText,
      availableCategories: availableCategories,
      detectedBarcode: detectedBarcode,
      imagePath: displayPath,
    );
  }

  /// Removes generic camera filename prefixes (e.g. image_picker_xxx, CAP_xxx, IMG_xxx).
  static String _cleanFilename(String filename) {
    var clean = filename.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    // If it's a generic camera app name, ignore it completely
    final isGeneric = RegExp(
      r'^(image[\s_-]*picker|scaled[\s_-]*image|cap[\s_-]*|img[\s_-]*|photo[\s_-]*|pxl[\s_-]*|scan[\s_-]*)[0-9\s_-]*$',
      caseSensitive: false,
    ).hasMatch(clean);

    if (isGeneric) return '';

    return clean.replaceAll(RegExp(r'[-_]'), ' ').trim();
  }

  /// Parses text from OCR / label / description into structured product fields.
  static ProductVisionResult parseText(
    String text, {
    List<String>? availableCategories,
    String? detectedBarcode,
    String? imagePath,
  }) {
    final raw = text.trim();
    if (raw.isEmpty) {
      return ProductVisionResult(
        name: 'Motorcycle Part',
        sellingPrice: 0.0,
        costPrice: 0.0,
        barcode: detectedBarcode,
        confidence: detectedBarcode != null ? 0.4 : 0.0,
        imagePath: imagePath,
        rawText: '',
      );
    }

    // 1. Detect Brand
    String? detectedBrand;
    for (final brand in knownBrands) {
      final pattern = RegExp(
        '\\b${RegExp.escape(brand)}\\b',
        caseSensitive: false,
      );
      if (pattern.hasMatch(raw)) {
        detectedBrand = brand;
        break;
      }
    }

    // 2. Detect Part Number
    // Common patterns:
    // Honda: 06455-KRE-G01, 12251-K16-900, 22102-K44-V00
    // Yamaha: 5TL-E7641-00, 2DP-E7641-00, B65-E7641-00
    // Spark Plugs: CPR8EA-9, CR7HSA, D8EA, BR8ES
    // Generic: ABC-1234-XYZ, RCB-01SH-02
    String? detectedPartNumber;
    final partNumberPatterns = [
      RegExp(r'\b[0-9]{5}-[A-Z0-9]{3,4}-[A-Z0-9]{3,4}\b', caseSensitive: false),
      RegExp(r'\b[A-Z0-9]{3}-[A-Z0-9]{5}-[0-9]{2}\b', caseSensitive: false),
      RegExp(r'\b(CPR|CR|D|BR)[0-9]{1,2}[A-Z]{1,3}(-[0-9]{1,2})?\b', caseSensitive: false),
      RegExp(r'\b[A-Z0-9]{3,5}-[A-Z0-9]{3,6}(-[A-Z0-9]{2,4})?\b', caseSensitive: false),
    ];

    for (final regex in partNumberPatterns) {
      final match = regex.firstMatch(raw);
      if (match != null) {
        detectedPartNumber = match.group(0)?.toUpperCase();
        break;
      }
    }

    // 3. Detect Barcode if not already found
    String? barcode = detectedBarcode;
    if (barcode == null || barcode.isEmpty) {
      final barcodeMatch = RegExp(r'\b[0-9]{8,14}\b').firstMatch(raw);
      if (barcodeMatch != null) {
        barcode = barcodeMatch.group(0);
      }
    }

    // 4. Detect Prices (SRP, Price, ₱, PHP)
    double? sellingPrice;
    double? costPrice;

    final srpRegex = RegExp(
      r'(?:srp|price|retail|selling)[:\s]*[₱p]?\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final srpMatch = srpRegex.firstMatch(raw);
    if (srpMatch != null) {
      final rawNum = srpMatch.group(1)?.replaceAll(',', '');
      sellingPrice = double.tryParse(rawNum ?? '');
    }

    final costRegex = RegExp(
      r'(?:cost|capital|puhunan|wholesale)[:\s]*[₱p]?\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final costMatch = costRegex.firstMatch(raw);
    if (costMatch != null) {
      final rawNum = costMatch.group(1)?.replaceAll(',', '');
      costPrice = double.tryParse(rawNum ?? '');
    }

    // Fallback price if just ₱xxx or PHP xxx found
    if (sellingPrice == null) {
      final genericPriceRegex = RegExp(
        r'(?:₱|php|[pP])\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      );
      final match = genericPriceRegex.firstMatch(raw);
      if (match != null) {
        final rawNum = match.group(1)?.replaceAll(',', '');
        sellingPrice = double.tryParse(rawNum ?? '');
      }
    }

    // Estimate cost if only selling price is present
    if (sellingPrice != null && costPrice == null && sellingPrice > 0) {
      costPrice = double.parse((sellingPrice * 0.78).toStringAsFixed(2));
    }

    // 5. Detect Category
    final lower = raw.toLowerCase();
    String detectedCategory = 'Accessories';

    if (lower.contains('oil') ||
        lower.contains('10w-40') ||
        lower.contains('10w-30') ||
        lower.contains('20w-50') ||
        lower.contains('4t') ||
        lower.contains('coolant') ||
        lower.contains('fluid') ||
        lower.contains('synthetic')) {
      detectedCategory = 'Oils & Fluids';
    } else if (lower.contains('brake') ||
        lower.contains('pad') ||
        lower.contains('caliper') ||
        lower.contains('rotor') ||
        lower.contains('shoe')) {
      detectedCategory = 'Brakes';
    } else if (lower.contains('tire') ||
        lower.contains('tyre') ||
        lower.contains('tubeless') ||
        lower.contains('tube') ||
        lower.contains('rim') ||
        lower.contains('mags')) {
      detectedCategory = 'Tires & Wheels';
    } else if (lower.contains('shock') ||
        lower.contains('monoshock') ||
        lower.contains('fork') ||
        lower.contains('suspension')) {
      detectedCategory = 'Suspension';
    } else if (lower.contains('belt') ||
        lower.contains('roller') ||
        lower.contains('flyball') ||
        lower.contains('pulley') ||
        lower.contains('clutch') ||
        lower.contains('chain') ||
        lower.contains('sprocket')) {
      detectedCategory = 'Drive & Transmission';
    } else if (lower.contains('plug') ||
        lower.contains('battery') ||
        lower.contains('light') ||
        lower.contains('led') ||
        lower.contains('bulb') ||
        lower.contains('horn') ||
        lower.contains('relay') ||
        lower.contains('stator') ||
        lower.contains('cdi')) {
      detectedCategory = 'Electrical & Lights';
    } else if (lower.contains('exhaust') ||
        lower.contains('pipe') ||
        lower.contains('muffler') ||
        lower.contains('filter') ||
        lower.contains('carb') ||
        lower.contains('throttle')) {
      detectedCategory = 'Exhaust & Engine';
    }

    // Match with user's available shop categories if provided
    if (availableCategories != null && availableCategories.isNotEmpty) {
      final exact = availableCategories.firstWhere(
        (c) => c.toLowerCase() == detectedCategory.toLowerCase(),
        orElse: () => '',
      );
      if (exact.isNotEmpty) {
        detectedCategory = exact;
      } else {
        // Find closest match
        final match = availableCategories.firstWhere(
          (c) =>
              c.toLowerCase().contains(detectedCategory.toLowerCase()) ||
              detectedCategory.toLowerCase().contains(c.toLowerCase()),
          orElse: () => availableCategories.first,
        );
        detectedCategory = match;
      }
    }

    // 6. Generate Clean Product Name
    String cleanName = raw;
    cleanName = cleanName.replaceAll(
      RegExp(r'\.(jpe?g|png|webp|bmp|heic)\b', caseSensitive: false),
      '',
    );
    // Remove camera prefix patterns
    cleanName = cleanName
        .replaceAll(
          RegExp(r'\b(IMG|PHOTO|PXL|SCAN|IMAGE_PICKER|SCALED_IMAGE)[\s_\-]*[0-9_\-\s]*\b',
              caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleanName.isEmpty) {
      final parts = [
        ?detectedBrand,
        detectedCategory,
        ?detectedPartNumber,
      ];
      cleanName = parts.isNotEmpty ? parts.join(' ') : 'Motorcycle Part';
    }

    // Capitalize words nicely
    cleanName = cleanName.split(' ').map((w) {
      if (w.isEmpty) return w;
      if (w.length <= 3 && w == w.toUpperCase()) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');

    return ProductVisionResult(
      name: cleanName.isNotEmpty ? cleanName : 'Motorcycle Part',
      brand: detectedBrand,
      partNumber: detectedPartNumber,
      category: detectedCategory,
      sellingPrice: sellingPrice ?? 0.0,
      costPrice: costPrice ?? 0.0,
      barcode: barcode,
      imagePath: imagePath,
      rawText: raw,
      confidence: (detectedBrand != null ? 0.35 : 0.1) +
          (detectedPartNumber != null ? 0.35 : 0.1) +
          (sellingPrice != null ? 0.2 : 0.0) +
          (barcode != null ? 0.1 : 0.0),
    );
  }
}
