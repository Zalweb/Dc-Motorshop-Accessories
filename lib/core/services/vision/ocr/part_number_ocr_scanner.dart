import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ocr_service.dart';
import '../../../theme/app_colors.dart';

/// Modal dialog and utility for scanning motorcycle part numbers and labels
/// using Apple Vision / MLKit Camera OCR.
class PartNumberOcrScanner {
  /// Launches camera or gallery picker to scan and extract a motorcycle part number.
  /// Returns the selected or detected part number, or null if cancelled.
  static Future<String?> scan(
    BuildContext context, {
    String title = 'Scan Part Number',
    String? subtitle,
  }) async {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    // 1. Pick Image Source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle ??
                              'Scan labels, boxes, or stamped codes on motorcycle parts',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_enhance_rounded,
                    color: AppColors.accent,
                  ),
                ),
                title: const Text(
                  'Take Photo with Camera',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Capture motorcycle part label or engraving',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.active.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.active,
                  ),
                ),
                title: const Text(
                  'Choose from Photo Library',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Select existing part photo from device storage',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );
    } catch (e) {
      debugPrint('PartNumberOcrScanner pickImage error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access camera/photos: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return null;
    }

    if (file == null) return null;
    if (!context.mounted) return null;

    // 2. Show Processing Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanning with Vision OCR...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Extracting motorcycle part numbers',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    OcrResult ocrResult = OcrResult.empty;
    try {
      if (!kIsWeb) {
        ocrResult = await extractTextFromImageFile(file.path);
      }
    } catch (e) {
      debugPrint('PartNumberOcrScanner OCR extraction error: $e');
    }

    if (!context.mounted) return null;
    Navigator.of(context).pop(); // Dismiss loading dialog

    final candidates = ocrResult.extractPartNumbers();

    if (candidates.isEmpty && (ocrResult.lines.isEmpty || kIsWeb)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'Camera Vision OCR runs natively on iOS & Android. Please enter part number manually.'
                  : 'No part numbers detected. Please ensure packaging label is well lit.',
            ),
            backgroundColor: AppColors.border,
          ),
        );
      }
      return null;
    }

    // If exactly one high-confidence part number detected, return it immediately
    if (candidates.isNotEmpty && candidates.length == 1 && candidates.first.confidence >= 0.85) {
      final code = candidates.first.code;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('Detected part #: $code'),
              ],
            ),
            backgroundColor: AppColors.active,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return code;
    }

    // 3. If multiple candidates or raw lines, show Candidate Selection Sheet
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final content = _PartNumberSelectionSheet(
          candidates: candidates,
          allLines: ocrResult.lines,
        );

        if (isDesktop) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              child: content,
            ),
          );
        }

        return FractionallySizedBox(
          heightFactor: 0.70,
          child: content,
        );
      },
    );
  }
}

class _PartNumberSelectionSheet extends StatelessWidget {
  final List<PartNumberCandidate> candidates;
  final List<String> allLines;

  const _PartNumberSelectionSheet({
    required this.candidates,
    required this.allLines,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Part Number',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Tap the part number or text from the scanned part',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  if (candidates.isNotEmpty) ...[
                    const Text(
                      'DETECTED PART NUMBERS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...candidates.map(
                      (c) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(
                                c.code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (c.brand != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c.brand!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            'From line: "${c.source}"',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          onTap: () => Navigator.pop(context, c.code),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (allLines.isNotEmpty) ...[
                    const Text(
                      'ALL DETECTED TEXT LINES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...allLines
                        .map((l) => l.trim())
                        .where((l) => l.isNotEmpty)
                        .map(
                          (line) => InkWell(
                            onTap: () => Navigator.pop(context, line),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 10,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.text_fields_rounded,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      line,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ],
                  if (candidates.isEmpty && allLines.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No text or part numbers recognized in photo.\nPlease ensure clear lighting and focus.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
