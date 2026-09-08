import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_result.dart';

export 'ocr_result.dart';

/// Native (Android / iOS) OCR text recognition using Google ML Kit.
Future<OcrResult> extractTextFromImageFile(String filePath) async {
  if (kIsWeb) return OcrResult.empty;

  // Google ML Kit text recognition is supported natively on Android and iOS
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return OcrResult.empty;
  }

  TextRecognizer? textRecognizer;
  try {
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFilePath(filePath);
    final recognizedText = await textRecognizer.processImage(inputImage);

    final lines = <String>[];
    final blocks = <String>[];

    for (final block in recognizedText.blocks) {
      final bText = block.text.trim();
      if (bText.isNotEmpty) {
        blocks.add(bText);
      }
      for (final line in block.lines) {
        final lText = line.text.trim();
        if (lText.isNotEmpty) {
          lines.add(lText);
        }
      }
    }

    return OcrResult(
      text: recognizedText.text,
      lines: lines,
      blocks: blocks,
    );
  } catch (e) {
    debugPrint('OCR extraction error: $e');
    return OcrResult.empty;
  } finally {
    try {
      await textRecognizer?.close();
    } catch (_) {}
  }
}
