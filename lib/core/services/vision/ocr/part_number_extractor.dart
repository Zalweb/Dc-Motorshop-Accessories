/// Candidate motorcycle part number extracted via Apple Vision / MLKit OCR.
class PartNumberCandidate {
  final String code;
  final String? brand;
  final double confidence;
  final String source;

  const PartNumberCandidate({
    required this.code,
    this.brand,
    required this.confidence,
    required this.source,
  });

  @override
  String toString() => 'PartNumberCandidate(code: $code, brand: $brand, confidence: $confidence)';
}

/// Specialized extractor for motorcycle part numbers and OEM codes from OCR text.
class PartNumberExtractor {
  // Common brand names for brand attribution
  static const Map<String, List<String>> _brandPatterns = {
    'Honda': ['honda', 'kre', 'k16', 'k44', 'kpp', 'kzl', 'kvb', 'k59'],
    'Yamaha': ['yamaha', 'yamalube', '5tl', '2dp', 'b65', '2ph', 'e7641', 'f5805'],
    'Suzuki': ['suzuki', 'raider', 'smash', 'gixxer', 'burgman'],
    'Kawasaki': ['kawasaki', 'barako', 'ninja', 'fury'],
    'NGK': ['ngk', 'laser iridium', 'spark plug', 'cpr8', 'cpr9', 'cr7', 'cr8', 'd8ea', 'br8'],
    'RCB': ['rcb', 'racing boy'],
    'Uma Racing': ['uma', 'uma racing'],
    'Brembo': ['brembo'],
    'Nissin': ['nissin'],
  };

  /// Extracts candidate part numbers from raw OCR text or OCR lines.
  static List<PartNumberCandidate> extractCandidates(
    String rawText, {
    List<String>? lines,
  }) {
    final results = <PartNumberCandidate>[];
    final seenCodes = <String>{};

    void addCandidate(String rawCode, double baseConfidence, String source) {
      final code = rawCode.trim().toUpperCase();
      if (code.length < 4 || code.length > 28) return;
      if (seenCodes.contains(code)) return;

      // Filter out non-part noise
      if (isIgnoredToken(code)) return;

      // Infer brand from context or code prefixes
      String? inferredBrand;
      final lowerContext = '$code $source $rawText'.toLowerCase();
      for (final entry in _brandPatterns.entries) {
        for (final kw in entry.value) {
          if (lowerContext.contains(kw)) {
            inferredBrand = entry.key;
            break;
          }
        }
        if (inferredBrand != null) break;
      }

      seenCodes.add(code);
      results.add(
        PartNumberCandidate(
          code: code,
          brand: inferredBrand,
          confidence: baseConfidence,
          source: source,
        ),
      );
    }

    final allLines = lines != null && lines.isNotEmpty
        ? lines
        : rawText.split(RegExp(r'[\r\n]+'));

    // 1. Check line-by-line for explicitly labeled part numbers (highest confidence)
    // e.g. "P/N: 06455-KRE-G01", "Part No: 5TL-E7641-00", "ITEM NO: RCB-01"
    final labeledRegex = RegExp(
      r'\b(?:p/?n|part\s*(?:no|number|#|num)?|item\s*(?:no|#|code)?|oem\s*(?:no|#)?)\b[:\s]*([A-Z0-9\-_]{4,24})',
      caseSensitive: false,
    );

    for (final line in allLines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Discard lines explicitly identifying barcodes or prices
      if (RegExp(r'^\s*(?:barcode|ean|upc|sku|qr\s*code|srp|price|php|₱)\b', caseSensitive: false).hasMatch(trimmed)) {
        continue;
      }

      final match = labeledRegex.firstMatch(trimmed);
      if (match != null) {
        final extracted = match.group(1);
        if (extracted != null && extracted.isNotEmpty && !isIgnoredToken(extracted)) {
          addCandidate(extracted, 0.95, trimmed);
        }
      }
    }

    // 2. High-precision motorcycle OEM part number regexes
    final highPrecisionPatterns = [
      // Honda OEM: 5 digits - 3 alphanumeric - 3 to 4 alphanumeric (e.g. 06455-KRE-G01, 12251-K16-900)
      (RegExp(r'\b[0-9]{5}-[A-Z0-9]{3}-[A-Z0-9]{3,4}\b', caseSensitive: false), 0.93),
      // Yamaha OEM: 3-4 alphanumeric - 5 alphanumeric - 2 digits (e.g. 5TL-E7641-00, 2DP-E7641-00, B65-E7641-00)
      (RegExp(r'\b[A-Z0-9]{3,4}-[A-Z0-9]{5}-[0-9]{2}\b', caseSensitive: false), 0.93),
      // Suzuki OEM: 5 digits - 5 digits (optional 3 alphanumeric suffix) (e.g. 16510-05240, 27600-09J01-120)
      (RegExp(r'\b[0-9]{5}-[0-9]{5}(-[A-Z0-9]{3})?\b', caseSensitive: false), 0.90),
      // Kawasaki OEM: 5 digits - 4 digits (optional 2-4 suffix) (e.g. 13008-0027)
      (RegExp(r'\b[0-9]{5}-[0-9]{4}(-[A-Z0-9]{2,4})?\b', caseSensitive: false), 0.90),
      // Spark Plugs (NGK, Denso, Bosch): e.g. CPR8EA-9, CR7HSA, D8EA, BR8ES, BKR6E-11
      (RegExp(r'\b(CPR|CR|BR|D|BKR|BP|C|U|W)[0-9]{1,2}[A-Z]{1,4}(-[0-9]{1,2})?\b', caseSensitive: false), 0.92),
      // Aftermarket brand models: e.g. 01LS002-RCB, RCB-01SH-02, UMA-02001, DID428HD-120
      (RegExp(r'\b[A-Z0-9]{3,6}-[A-Z0-9]{3,6}(-[A-Z0-9]{2,4})?\b', caseSensitive: false), 0.85),
    ];

    for (final line in allLines) {
      final trimmed = line.trim();
      for (final (regex, conf) in highPrecisionPatterns) {
        for (final match in regex.allMatches(trimmed)) {
          final matched = match.group(0);
          if (matched != null) {
            addCandidate(matched, conf, trimmed);
          }
        }
      }
    }

    // 3. Fallback: single standalone uppercase token on its own line that looks like a part code
    for (final line in allLines) {
      final trimmed = line.trim();
      // Standalone code line (e.g. "06455KREG01", "2DPE764100")
      if (RegExp(r'^[A-Z0-9]{6,16}$', caseSensitive: false).hasMatch(trimmed)) {
        // Must contain at least one digit and one letter to not be pure word or pure number
        final hasLetter = RegExp(r'[A-Za-z]').hasMatch(trimmed);
        final hasDigit = RegExp(r'[0-9]').hasMatch(trimmed);
        if (hasLetter && hasDigit && !isIgnoredToken(trimmed)) {
          addCandidate(trimmed, 0.70, trimmed);
        }
      }
    }

    // Sort by confidence descending
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  /// Returns the top candidate part number, or null if none detected.
  static String? extractBestPartNumber(String rawText, {List<String>? lines}) {
    final candidates = extractCandidates(rawText, lines: lines);
    return candidates.isNotEmpty ? candidates.first.code : null;
  }

  /// Filters false positives like oil viscosity, tire sizes, dates, barcodes, and noise words.
  static bool isIgnoredToken(String token) {
    final upper = token.toUpperCase().trim();
    if (upper.length < 3) return true;

    // Oil viscosity specs (e.g. 10W-30, 10W-40, 10W40, 20W-50, 20W50, 15W-40, 5W-30, 5W-40, 4T, 2T)
    if (RegExp(r'^(?:SAE\s*)?[0-9]{1,2}W-?[0-9]{2}(?:-4T|-2T)?$|^[124]T$').hasMatch(upper)) {
      return true;
    }

    // Tire size patterns (e.g. 90/80-14, 110/70-17, 120/70R17, 2.50-17, 3.00-17)
    if (RegExp(r'^[0-9]{2,3}/[0-9]{2,3}[-R/zZ]{1,2}[0-9]{2}$').hasMatch(upper)) {
      return true;
    }
    if (RegExp(r'^[0-9]\.[0-9]{2}-[0-9]{2}$').hasMatch(upper)) {
      return true;
    }

    // Standard retail barcodes (pure 8, 12, 13, 14 digits)
    if (RegExp(r'^[0-9]{8}$|^[0-9]{12,14}$').hasMatch(upper)) {
      return true;
    }

    // Volumes, capacities, and ratings (e.g. 800ML, 1000ML, 1L, 4L, 125CC, 150CC, 155CC)
    if (RegExp(r'^[0-9]+(?:ML|CC|LITER|LTR|L|G|KG|V|AH|W)$').hasMatch(upper)) {
      return true;
    }
    if (RegExp(r'^[0-9]+V-[0-9]+(?:AH|W)$').hasMatch(upper)) {
      return true;
    }

    // Quantities (e.g. QTY-1, 1PC, 1SET)
    if (RegExp(r'^(?:QTY|PACK|PCS|PIECE|SET)[-:\s]*[0-9]+$|^[0-9]+(?:PCS|PC|SET)$').hasMatch(upper)) {
      return true;
    }

    // Dates (e.g. 2026-09-08, 2024/01/15)
    if (RegExp(r'^202[0-9][\-/][0-1][0-9][\-/][0-3][0-9]$').hasMatch(upper)) {
      return true;
    }

    // Common non-part keywords
    const noiseWords = {
      'MADE',
      'JAPAN',
      'THAILAND',
      'INDONESIA',
      'PHILIPPINES',
      'MALAYSIA',
      'CHINA',
      'VIETNAM',
      'GENUINE',
      'ORIGINAL',
      'PARTS',
      'ACCESSORIES',
      'LIMITED',
      'COMPANY',
      'CORP',
      'MOTOR',
      'HONDA',
      'YAMAHA',
      'SUZUKI',
      'KAWASAKI',
      'PRICE',
      'TOTAL',
      'RETAIL',
      'BARCODE',
      'EAN',
      'UPC',
      'SKU',
      'SRP',
      'PHP',
      'PESO',
      'PESOS',
      'PIECE',
      'PIECES',
      'PACK',
      'FRONT',
      'REAR',
      'SAFETY',
      'QUALITY',
      'BATCH',
      'DATE',
    };

    if (noiseWords.contains(upper)) {
      return true;
    }

    return false;
  }
}
