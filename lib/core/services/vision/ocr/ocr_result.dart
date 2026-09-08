import 'part_number_extractor.dart';

export 'part_number_extractor.dart';

/// Represents the result of OCR text recognition on an image.
class OcrResult {
  final String text;
  final List<String> lines;
  final List<String> blocks;

  const OcrResult({
    required this.text,
    this.lines = const [],
    this.blocks = const [],
  });

  static const empty = OcrResult(text: '');

  bool get isEmpty => text.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Extracts structured motorcycle part number candidates found in this OCR result.
  List<PartNumberCandidate> extractPartNumbers() {
    return PartNumberExtractor.extractCandidates(text, lines: lines);
  }

  /// Extracts the most confident part number detected, or null if none.
  String? get bestPartNumber => PartNumberExtractor.extractBestPartNumber(text, lines: lines);
}
