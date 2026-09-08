import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/security_sanitizer.dart';

/// Professional full-screen camera scanner for barcodes and product labels.
///
/// Features:
/// - Dark immersive viewfinder with rounded cutout and dimmed mask
/// - Glowing accent corner brackets and animated scanning laser beam
/// - Floating frosted HUD for Torch, Camera Flip, and Gallery Image Pick
/// - Tactile haptic feedback on successful detection
/// - Offline ML Kit scanning across Android, iOS, and Web
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  late final AnimationController _laserController;
  late final Animation<double> _laserAnimation;

  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null) return;
    final value = sanitizeBarcode(rawValue);
    if (value.isEmpty) return;

    _handled = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(value);
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;

      if (!kIsWeb) {
        final capture = await _controller.analyzeImage(image.path);
        final rawValue = capture?.barcodes.firstOrNull?.rawValue;
        if (rawValue != null) {
          final value = sanitizeBarcode(rawValue);
          if (value.isNotEmpty && mounted) {
            _handled = true;
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(value);
            return;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No barcode found in selected image. Try another photo.'),
            backgroundColor: AppColors.bgSurface2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not scan image: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 400;
    final scanWidth = isCompact ? size.width * 0.78 : 280.0;
    final scanHeight = isCompact ? 170.0 : 190.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera Feed ─────────────────────────────────────────────
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_outlined,
                              size: 48, color: AppColors.accent),
                          const SizedBox(height: 16),
                          Text(
                            error.errorCode == MobileScannerErrorCode.permissionDenied
                                ? 'Camera Permission Denied'
                                : 'Camera Scanner Unavailable',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.errorDetails?.message ??
                                'Please check camera permissions in device settings and try again.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Try Again'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _controller.start(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Dimmed Viewfinder Mask & Cutout ──────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                cutoutSize: Size(scanWidth, scanHeight),
                borderRadius: 20,
              ),
            ),
          ),

          // ── Animated Laser Line ──────────────────────────────────────
          Center(
            child: SizedBox(
              width: scanWidth,
              height: scanHeight,
              child: AnimatedBuilder(
                animation: _laserAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Positioned(
                        top: scanHeight * _laserAnimation.value,
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.accent,
                                Color(0xFF00E5FF),
                                AppColors.accent,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Top Bar Controls & Status ────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    // Header badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.active,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'SCANNER ACTIVE',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Torch toggle button
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _controller,
                      builder: (context, state, child) {
                        final isOn = state.torchState == TorchState.on;
                        return InkWell(
                          onTap: () => _controller.toggleTorch(),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isOn
                                  ? Colors.amber.withValues(alpha: 0.3)
                                  : AppColors.bgSurface.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isOn
                                    ? Colors.amber
                                    : Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Icon(
                              isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                              color: isOn ? Colors.amber : Colors.white70,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Viewfinder Hint Text ─────────────────────────────────────
          Positioned(
            left: 24,
            right: 24,
            top: (size.height / 2) + (scanHeight / 2) + 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Text(
                    'Align barcode or QR code within the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Controls Dock ─────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Camera flip
                      TextButton.icon(
                        icon: const Icon(Icons.flip_camera_ios_rounded,
                            size: 18, color: Colors.white70),
                        label: const Text(
                          'Flip Camera',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _controller.switchCamera(),
                      ),

                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),

                      // Gallery picker
                      TextButton.icon(
                        icon: const Icon(Icons.photo_library_rounded,
                            size: 18, color: AppColors.accent),
                        label: const Text(
                          'From Gallery',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _pickFromGallery,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that creates a darkened mask over the screen with
/// a rounded transparent cutout and stylized glowing corner brackets.
class _ScannerOverlayPainter extends CustomPainter {
  final Size cutoutSize;
  final double borderRadius;

  const _ScannerOverlayPainter({
    required this.cutoutSize,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final cutoutRect = Rect.fromCenter(
      center: center,
      width: cutoutSize.width,
      height: cutoutSize.height,
    );
    final cutoutRRect = RRect.fromRectAndRadius(
      cutoutRect,
      Radius.circular(borderRadius),
    );

    // Dark background with transparent hole
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutoutRRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Subtle outline around cutout
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(cutoutRRect, outlinePaint);

    // Glowing corner brackets
    final cornerPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    final r = borderRadius;
    final l = cutoutRect.left;
    final t = cutoutRect.top;
    final rgt = cutoutRect.right;
    final b = cutoutRect.bottom;

    // Top-Left Corner
    final tlPath = Path()
      ..moveTo(l, t + r + cornerLength)
      ..lineTo(l, t + r)
      ..arcToPoint(Offset(l + r, t), radius: Radius.circular(r))
      ..lineTo(l + r + cornerLength, t);
    canvas.drawPath(tlPath, cornerPaint);

    // Top-Right Corner
    final trPath = Path()
      ..moveTo(rgt - r - cornerLength, t)
      ..lineTo(rgt - r, t)
      ..arcToPoint(Offset(rgt, t + r), radius: Radius.circular(r))
      ..lineTo(rgt, t + r + cornerLength);
    canvas.drawPath(trPath, cornerPaint);

    // Bottom-Left Corner
    final blPath = Path()
      ..moveTo(l, b - r - cornerLength)
      ..lineTo(l, b - r)
      ..arcToPoint(Offset(l + r, b), radius: Radius.circular(r))
      ..lineTo(l + r + cornerLength, b);
    canvas.drawPath(blPath, cornerPaint);

    // Bottom-Right Corner
    final brPath = Path()
      ..moveTo(rgt - r - cornerLength, b)
      ..lineTo(rgt - r, b)
      ..arcToPoint(Offset(rgt, b - r), radius: Radius.circular(r))
      ..lineTo(rgt, b - r - cornerLength);
    canvas.drawPath(brPath, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.cutoutSize != cutoutSize ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Pushes the scanner and returns the scanned barcode, or null if cancelled.
Future<String?> scanBarcode(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
  );
}
