import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/models/product.dart';
import 'ocr/ocr_service.dart';
import 'product_vision_models.dart';

/// Service responsible for scanning motorcycle parts & product labels,
/// extracting part numbers, brands, categories, prices, and barcodes using
/// on-device optical character recognition (OCR) and barcode analysis.
class ProductVisionService {
  static const List<String> knownBrands = [
    'Motul',
    'Castrol',
    'Repsol',
    'Yamalube',
    'Shell Advance',
    'Shell',
    'Pertua',
    'Mobil 1',
    'Mobil',
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
    'Deestone',
    'Camel',
    'Leo',
    'Vee Rubber',
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
    'Outdo',
    'Dynavolt',
    'DID',
    'SSS',
    'RK Takasago',
    'RK',
    'Bando',
    'Gates',
    'Mitsuboshi',
    'RS8',
    'Spec V',
    'Sun Racing',
    'APIDO',
    'DAENG',
    'SC Project',
    'SEC',
    'Givi',
    'Shad',
    'Evo',
    'HJC',
    'KYT',
    'Spyder',
    'MT Helmets',
    'NHK',
    'Index',
    'Zeneos',
    'TDR',
    'Option 1',
    'FKM',
    'Speedmetal',
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

  /// Common motorcycle models popular in the Philippines for fitment and compatibility detection.
  static const List<String> knownModels = [
    'Mio i125',
    'Mio Sporty',
    'Mio Soul i125',
    'Mio Gravis',
    'Mio Gear',
    'Mio 125 MXi',
    'Mio Soul',
    'Mio',
    'Click 125i',
    'Click 150i',
    'Click 160',
    'Click 125',
    'Click 150',
    'Click',
    'Aerox 155',
    'Aerox',
    'NMAX 155',
    'NMAX',
    'PCX 160',
    'PCX 150',
    'PCX',
    'ADV 160',
    'ADV 150',
    'ADV',
    'Wave 100',
    'Wave 110',
    'Wave 125',
    'Wave Alpha',
    'Wave',
    'XRM 110',
    'XRM 125',
    'XRM',
    'Raider 150 Fi',
    'Raider 150',
    'Raider',
    'Smash 115',
    'Smash 110',
    'Smash',
    'Barako 175',
    'Barako II',
    'Barako',
    'Sniper 150',
    'Sniper 155',
    'Sniper',
    'Beat Fi',
    'Beat',
    'Scoopy',
    'Winner X',
    'RS150',
    'Burgman Street 125',
    'Burgman Street',
    'Burgman',
    'Gixxer 150',
    'Gixxer 250',
    'TMX 125',
    'TMX 155',
    'TMX Supremo',
    'TMX',
    'R15',
    'MT-15',
    'CBR150R',
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

    // 1. Try barcode detection from image (native mobile only)
    String? detectedBarcode;
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
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

    // 2. Perform OCR Text Recognition from image
    OcrResult ocrResult = OcrResult.empty;
    if (!kIsWeb) {
      try {
        ocrResult = await extractTextFromImageFile(file.path);
      } catch (e) {
        debugPrint('ProductVision OCR error: $e');
      }
    }

    // 3. If barcode matches an existing shop product, auto-fill from that product!
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
            rawText: ocrResult.isNotEmpty
                ? ocrResult.text
                : 'Matched existing product: ${p.name}',
            confidence: 0.99,
          );
        }
      }
    }

    // 4. Synthesize text sources: user hint, OCR text, clean filename, and barcode
    final filenameClean = _cleanFilename(file.name);

    final textSources = <String>[
      if (hintText != null && hintText.trim().isNotEmpty) hintText.trim(),
      if (ocrResult.isNotEmpty) ocrResult.text.trim(),
      if (filenameClean.isNotEmpty) filenameClean,
      if (detectedBarcode != null && detectedBarcode.isNotEmpty)
        'Barcode: $detectedBarcode',
    ];

    final combinedText = textSources.join('\n');

    return parseText(
      combinedText,
      availableCategories: availableCategories,
      detectedBarcode: detectedBarcode,
      imagePath: displayPath,
      ocrLines: ocrResult.lines,
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
    List<String>? ocrLines,
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

    // 1. Detect Brand (prioritize longer multi-word brands first)
    String? detectedBrand;
    final sortedBrands = List<String>.from(knownBrands)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final brand in sortedBrands) {
      final pattern = RegExp(
        '\\b${RegExp.escape(brand)}\\b',
        caseSensitive: false,
      );
      if (pattern.hasMatch(raw)) {
        detectedBrand = brand;
        break;
      }
    }

    // Handle common brand aliases
    if (detectedBrand == null) {
      final upper = raw.toUpperCase();
      if (upper.contains('YAMALUBE')) {
        detectedBrand = 'Yamalube';
      } else if (upper.contains('RACING BOY') || upper.contains('RCB')) {
        detectedBrand = 'RCB';
      }
    }

    // 2. Detect Motorcycle Model Fitment / Compatibility
    String? detectedModel;
    for (final model in knownModels) {
      final pattern = RegExp(
        '\\b${RegExp.escape(model)}\\b',
        caseSensitive: false,
      );
      if (pattern.hasMatch(raw)) {
        detectedModel = model;
        break;
      }
    }

    // 3. Detect Part Number
    String? detectedPartNumber;

    // A. Check explicit labeled prefix (e.g. Part No: 06455-KRE-G01, Part: 104086, P/N: 2DP-E7641-00)
    final labeledPartRegex = RegExp(
      r'\b(?:part\s*(?:no|number|#|num)?|p\/?n|item\s*(?:no|code|#)?|model\s*(?:no|#)?|oem\s*(?:no|#)?)[:\s]+([A-Z0-9\-]{4,24})\b',
      caseSensitive: false,
    );
    final labeledPartMatch = labeledPartRegex.firstMatch(raw);
    if (labeledPartMatch != null && labeledPartMatch.group(1) != null) {
      final candidate = labeledPartMatch.group(1)!.trim().toUpperCase();
      if (_isValidPartNumber(candidate)) {
        detectedPartNumber = candidate;
      }
    }

    // B. Check standard motorcycle OEM patterns (extract entire match)
    if (detectedPartNumber == null) {
      final partNumberPatterns = [
        // Honda OEM: 06455-KRE-G01, 12251-K16-900, 22102-K44-V00
        RegExp(r'\b[0-9]{5}-[A-Z0-9]{3,4}-[A-Z0-9]{3,4}\b', caseSensitive: false),
        // Yamaha OEM: 5TL-E7641-00, 2DP-E7641-00, B65-E7641-00
        RegExp(r'\b[A-Z0-9]{3,4}-[A-Z0-9]{5}-[0-9]{2}\b', caseSensitive: false),
        RegExp(r'\b[A-Z0-9]{3}-[0-9]{5}-[0-9]{2}\b', caseSensitive: false),
        // Spark Plugs: CPR8EA-9, CR7HSA, D8EA, BR8ES, LMAR8A-9
        RegExp(
          r'\b(?:CPR|CR|D|BR|BPR|BP|MR|LMAR|C)[0-9]{1,2}[A-Z]{1,3}(?:-[0-9]{1,2}[A-Z]?)?\b',
          caseSensitive: false,
        ),
        // Generic formatted parts: ABC-1234-XYZ, RCB-01SH-02, 5TL-E7641
        RegExp(r'\b[A-Z0-9]{3,5}-[A-Z0-9]{3,6}(?:-[A-Z0-9]{2,4})?\b', caseSensitive: false),
      ];

      for (final regex in partNumberPatterns) {
        final match = regex.firstMatch(raw);
        if (match != null) {
          final candidate = match.group(0)!.trim().toUpperCase();
          if (_isValidPartNumber(candidate)) {
            detectedPartNumber = candidate;
            break;
          }
        }
      }
    }

    detectedPartNumber ??=
        PartNumberExtractor.extractBestPartNumber(raw, lines: ocrLines);

    // 4. Detect Barcode if not already found
    String? barcode = detectedBarcode;
    if (barcode == null || barcode.isEmpty) {
      // Check explicit label e.g. Barcode: 3374650247651
      final labeledMatch = RegExp(
        r'(?:barcode|ean|upc|sku)[:\s]*([0-9]{8,14})\b',
        caseSensitive: false,
      ).firstMatch(raw);

      if (labeledMatch != null) {
        barcode = labeledMatch.group(1);
      } else {
        // Fallback standalone 8-14 digit number
        final standaloneMatch = RegExp(r'\b[0-9]{8,14}\b').firstMatch(raw);
        if (standaloneMatch != null) {
          barcode = standaloneMatch.group(0);
        }
      }
    }

    // Ensure a retail barcode is never set as the part number
    if (detectedPartNumber != null) {
      if (detectedPartNumber == barcode ||
          RegExp(r'^[0-9]{8}$|^[0-9]{12,14}$').hasMatch(detectedPartNumber)) {
        barcode ??= detectedPartNumber;
        detectedPartNumber = null;
      }
    }

    // 5. Detect Prices (SRP, Price, Retail, Cost, Puhunan, ₱, PHP)
    double? sellingPrice;
    double? costPrice;

    final srpRegex = RegExp(
      r'(?:srp|price|retail|selling|presyo)[:\s]*[₱p]?\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final srpMatch = srpRegex.firstMatch(raw);
    if (srpMatch != null) {
      final rawNum = srpMatch.group(1)?.replaceAll(',', '');
      sellingPrice = double.tryParse(rawNum ?? '');
    }

    final costRegex = RegExp(
      r'(?:cost|capital|puhunan|wholesale|supplier)[:\s]*[₱p]?\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final costMatch = costRegex.firstMatch(raw);
    if (costMatch != null) {
      final rawNum = costMatch.group(1)?.replaceAll(',', '');
      costPrice = double.tryParse(rawNum ?? '');
    }

    // Fallback price if currency symbol ₱xxx or PHP xxx or Pxxx found without explicit keyword
    if (sellingPrice == null) {
      final currencyRegex = RegExp(
        r'(?:₱|\bphp\b|\b[pP])\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)(?!\s*[-/a-zA-Z0-9])',
        caseSensitive: false,
      );
      final match = currencyRegex.firstMatch(raw);
      if (match != null) {
        final rawNum = match.group(1)?.replaceAll(',', '');
        final parsed = double.tryParse(rawNum ?? '');
        // Require at least 5 pesos to prevent single-digit noise (e.g. 'Top 1' or '4T')
        if (parsed != null && parsed >= 5.0) {
          sellingPrice = parsed;
        }
      }
    }

    // Estimate cost if only selling price is present (~78% of retail)
    if (sellingPrice != null && costPrice == null && sellingPrice > 0) {
      costPrice = double.parse((sellingPrice * 0.78).toStringAsFixed(2));
    }

    // Estimate selling if only cost price is present (~130% of cost)
    if (costPrice != null && sellingPrice == null && costPrice > 0) {
      sellingPrice = double.parse((costPrice * 1.30).toStringAsFixed(2));
    }

    // 6. Detect Category & Specific Part Type
    String detectedCategory = 'General Parts';
    String? detectedPartType;

    final lower = raw.toLowerCase();

    if (lower.contains('oil') ||
        lower.contains('lubricant') ||
        lower.contains('synthetic') ||
        lower.contains('4t') ||
        lower.contains('2t') ||
        lower.contains('coolant') ||
        lower.contains('fluid') ||
        lower.contains('brake fluid')) {
      detectedCategory = 'Oils & Fluids';
      detectedPartType = lower.contains('coolant')
          ? 'Coolant'
          : lower.contains('brake fluid')
              ? 'Brake Fluid'
              : lower.contains('fork oil')
                  ? 'Fork Oil'
                  : 'Engine Oil';
    } else if (lower.contains('brake') ||
        lower.contains('pad') ||
        lower.contains('shoe') ||
        lower.contains('caliper') ||
        lower.contains('rotor') ||
        lower.contains('disc') ||
        lower.contains('lever')) {
      detectedCategory = 'Brakes';
      detectedPartType = lower.contains('shoe')
          ? 'Brake Shoe'
          : lower.contains('caliper')
              ? 'Brake Caliper'
              : lower.contains('lever')
                  ? 'Brake Lever'
                  : 'Brake Pads';
    } else if (lower.contains('tire') ||
        lower.contains('tyre') ||
        lower.contains('interior') ||
        lower.contains('tube') ||
        lower.contains('rim') ||
        lower.contains('mags')) {
      detectedCategory = 'Tires & Wheels';
      detectedPartType = lower.contains('tubeless')
          ? 'Tubeless Tire'
          : lower.contains('tube')
              ? 'Inner Tube'
              : 'Tire';
    } else if (lower.contains('shock') ||
        lower.contains('monoshock') ||
        lower.contains('fork') ||
        lower.contains('suspension')) {
      detectedCategory = 'Suspension';
      detectedPartType = lower.contains('monoshock')
          ? 'Monoshock'
          : 'Shock Absorber';
    } else if (lower.contains('belt') ||
        lower.contains('roller') ||
        lower.contains('flyball') ||
        lower.contains('clutch') ||
        lower.contains('chain') ||
        lower.contains('sprocket')) {
      detectedCategory = 'Drive & Transmission';
      detectedPartType = lower.contains('belt')
          ? 'V-Belt'
          : lower.contains('flyball') || lower.contains('roller')
              ? 'Flyball Rollers'
              : lower.contains('chain') || lower.contains('sprocket')
                  ? 'Drive Chain'
                  : 'Clutch Lining';
    } else if (lower.contains('plug') ||
        lower.contains('battery') ||
        lower.contains('light') ||
        lower.contains('bulb') ||
        lower.contains('horn') ||
        lower.contains('relay') ||
        lower.contains('stator') ||
        lower.contains('cdi')) {
      detectedCategory = 'Electrical & Lights';
      detectedPartType = lower.contains('battery')
          ? 'Battery'
          : lower.contains('plug')
              ? 'Spark Plug'
              : 'LED Bulb';
    } else if (lower.contains('exhaust') ||
        lower.contains('pipe') ||
        lower.contains('muffler') ||
        lower.contains('filter') ||
        lower.contains('carb') ||
        lower.contains('throttle')) {
      detectedCategory = 'Exhaust & Engine';
      detectedPartType = lower.contains('filter')
          ? 'Air Filter'
          : lower.contains('carb')
              ? 'Carburetor'
              : 'Exhaust Pipe';
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

    // 7. Generate Clean Product Name
    String cleanName = '';

    // If multi-line OCR lines are provided, smartly find non-boilerplate title line
    if (ocrLines != null && ocrLines.isNotEmpty) {
      final candidateLines = ocrLines
          .map((l) => l.trim())
          .where((l) => !_isBoilerplateLine(l))
          .where((l) {
            final lowerL = l.toLowerCase();
            // Discard line if it is ONLY the brand name alone (brand header/logo)
            if (detectedBrand != null && lowerL == detectedBrand.toLowerCase()) {
              return false;
            }
            // Discard line if it is ONLY the part number
            if (detectedPartNumber != null &&
                l.toUpperCase() == detectedPartNumber.toUpperCase()) {
              return false;
            }
            // Discard line if it is ONLY a barcode
            if (RegExp(r'^[0-9]{8,14}$').hasMatch(l)) {
              return false;
            }
            return true;
          })
          .toList();

      String? bestLine;
      for (final line in candidateLines) {
        final lowerLine = line.toLowerCase();
        // Check for motorcycle part keywords
        final hasPartKeyword = RegExp(
          r'\b(pad|pads|shoe|shoes|belt|chain|plug|plugs|filter|oil|fluid|disc|rotor|lever|levers|caliper|shock|monoshock|tire|tires|tube|tubes|mirror|mirrors|battery|light|lights|bulb|bulbs|pipe|pipes|exhaust|muffler|sprocket|roller|rollers|bearing|gasket|piston|ring|lining|clutch|carb|carburetor)\b',
          caseSensitive: false,
        ).hasMatch(lowerLine);

        final hasModel = detectedModel != null &&
            lowerLine.contains(detectedModel.toLowerCase());

        if (hasPartKeyword || hasModel) {
          bestLine = line;
          break;
        }
      }

      if (bestLine != null && bestLine.length >= 4) {
        cleanName = bestLine;
        // Prepend brand if not already in the title line
        if (detectedBrand != null &&
            !cleanName.toLowerCase().contains(detectedBrand.toLowerCase())) {
          cleanName = '$detectedBrand $cleanName';
        }
        // Append part number if available and not present
        if (detectedPartNumber != null &&
            !cleanName.toUpperCase().contains(detectedPartNumber.toUpperCase())) {
          cleanName = '$cleanName $detectedPartNumber';
        }
      } else {
        // Assemble clean name from detected components
        final parts = <String>[];
        if (detectedBrand != null && detectedBrand.isNotEmpty) parts.add(detectedBrand);
        parts.add(detectedPartType ?? detectedCategory);
        if (detectedModel != null && detectedModel.isNotEmpty) parts.add(detectedModel);
        if (detectedPartNumber != null && detectedPartNumber.isNotEmpty) parts.add(detectedPartNumber);
        if (parts.isNotEmpty) {
          cleanName = parts.join(' ');
        }
      }
    }

    // If still empty, fall back to cleaning raw string
    if (cleanName.isEmpty) {
      cleanName = raw;
    }

    // Strip image file extensions
    cleanName = cleanName.replaceAll(
      RegExp(r'\.(jpe?g|png|webp|bmp|heic)\b', caseSensitive: false),
      '',
    );

    // Strip camera prefix patterns
    cleanName = cleanName.replaceAll(
      RegExp(
        r'\b(IMG|PHOTO|PXL|SCAN|IMAGE_PICKER|SCALED_IMAGE)[\s_\-]*[0-9_\-\s]*\b',
        caseSensitive: false,
      ),
      '',
    );

    // Strip explicit SRP/Price tokens from the product name
    cleanName = cleanName.replaceAll(
      RegExp(
        r'\b(?:srp|price|retail|cost|capital|puhunan|php|₱)\b[:\s]*[₱p]?\s*[0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?\b',
        caseSensitive: false,
      ),
      '',
    );
    cleanName = cleanName.replaceAll(
      RegExp(r'₱\s*[0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?'),
      '',
    );

    // Strip explicit Barcode tokens from the product name
    cleanName = cleanName.replaceAll(
      RegExp(r'\b(barcode|ean|upc)[:\s]*[0-9]{8,14}\b', caseSensitive: false),
      '',
    );

    // Clean whitespace
    cleanName = cleanName.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Fallback if name was completely stripped
    if (cleanName.isEmpty) {
      final parts = <String>[];
      if (detectedBrand != null && detectedBrand.isNotEmpty) parts.add(detectedBrand);
      parts.add(detectedPartType ?? detectedCategory);
      if (detectedModel != null && detectedModel.isNotEmpty) parts.add(detectedModel);
      if (detectedPartNumber != null && detectedPartNumber.isNotEmpty) parts.add(detectedPartNumber);
      cleanName = parts.isNotEmpty ? parts.join(' ') : 'Motorcycle Part';
    }

    // Capitalize words nicely (keeping acronyms and part numbers uppercase)
    const acronyms = {
      'RCB', 'OEM', 'NGK', 'LED', 'CST', 'DID', 'SSS', 'JRP', 'FDR',
      'IRC', 'KYB', 'YSS', 'CDI', 'TDR', 'RK', 'SEC', 'HJC', 'KYT',
      'SRP', 'PHP', 'FR', 'RR', 'DOT', 'SAE', 'AT', 'MT', 'MF', 'ABS',
    };

    cleanName = cleanName.split(' ').map((w) {
      if (w.isEmpty) return w;
      final upper = w.toUpperCase();

      // If it contains hyphen or digits (part number e.g. 06455-KRE-G01), preserve uppercase
      if (w.contains('-') || RegExp(r'[0-9]').hasMatch(w)) {
        return upper;
      }

      // If known acronym, keep uppercase
      final cleanWord = upper.replaceAll(RegExp(r'[^A-Z]'), '');
      if (acronyms.contains(cleanWord)) {
        return upper;
      }

      // Title case regular words
      return upper[0] + w.substring(1).toLowerCase();
    }).join(' ');

    // 8. Generate Structured Product Description
    final descParts = <String>[];
    if (detectedBrand != null) descParts.add('Brand: $detectedBrand');
    if (detectedPartType != null) descParts.add('Type: $detectedPartType');
    if (detectedPartNumber != null) descParts.add('Part #: $detectedPartNumber');
    if (detectedModel != null) descParts.add('Model Fit: $detectedModel');
    if (detectedCategory != 'General Parts') descParts.add('Category: $detectedCategory');
    if (barcode != null) descParts.add('Barcode: $barcode');
    final structuredDescription =
        descParts.isNotEmpty ? descParts.join(' • ') : null;

    // Calculate confidence
    double confidence = (detectedBrand != null ? 0.30 : 0.1) +
        (detectedPartNumber != null ? 0.35 : 0.1) +
        (detectedModel != null ? 0.10 : 0.0) +
        (sellingPrice != null ? 0.15 : 0.0) +
        (barcode != null ? 0.1 : 0.0);

    return ProductVisionResult(
      name: cleanName.isNotEmpty ? cleanName : 'Motorcycle Part',
      brand: detectedBrand,
      partNumber: detectedPartNumber,
      model: detectedModel,
      category: detectedCategory,
      sellingPrice: sellingPrice ?? 0.0,
      costPrice: costPrice ?? 0.0,
      barcode: barcode,
      description: structuredDescription,
      imagePath: imagePath,
      rawText: raw,
      confidence: confidence.clamp(0.0, 0.99),
    );
  }

  /// Checks whether a candidate string is a valid part number rather than
  /// a viscosity, tire size, date, volume spec, or common label word.
  static bool _isValidPartNumber(String candidate) {
    return !PartNumberExtractor.isIgnoredToken(candidate);
  }

  /// Identifies common boilerplate lines in motorcycle parts packaging
  /// that should not become product names.
  static bool _isBoilerplateLine(String line) {
    final l = line.toLowerCase().trim();
    if (l.isEmpty || l.length < 3) return true;

    const boilerplate = [
      'made in',
      'distributed by',
      'manufactured by',
      'produced by',
      'genuine parts',
      'original parts',
      'genuine accessories',
      'accessories',
      'net weight',
      'net contents',
      'gross weight',
      'keep out of reach',
      'caution',
      'warning',
      'batch',
      'lot no',
      'mfg date',
      'exp date',
      'barcode',
      'srp',
      'puhunan',
      'price',
      'php',
      'pesos',
      'for motorcycle use',
      'motorcycle use only',
      'motor co',
      'corporation',
      'co., ltd',
      'co. ltd',
      'philippines',
      'thailand',
      'japan',
      'indonesia',
      'vietnam',
      'china',
      'malaysia',
      'quantity',
      'qty',
      '1 pc',
      '1 piece',
      '1 set',
      'safety first',
      'quality guaranteed',
      'iso 9001',
      'iso 9002',
      'all rights reserved',
      'patent pending',
      'www.',
      '.com',
      'tel:',
      'fax:',
      'email:',
    ];

    for (final term in boilerplate) {
      if (l.contains(term)) return true;
    }

    return false;
  }
}
