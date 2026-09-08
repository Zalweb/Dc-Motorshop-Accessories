import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/vision/product_vision_models.dart';
import '../../../core/services/vision/product_vision_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/app_image.dart';

/// Modal dialog that presents an accurate, high-tech animated scanning experience
/// for motorcycle part packaging and labels.
class ProductVisionScanningModal extends StatefulWidget {
  final XFile imageFile;
  final List<String> categories;
  final List<Product>? existingProducts;

  const ProductVisionScanningModal({
    super.key,
    required this.imageFile,
    required this.categories,
    this.existingProducts,
  });

  /// Displays the scanning animation modal while asynchronously parsing the packaging image.
  /// Returns the resolved [ProductVisionResult], or `null` if cancelled or failed.
  static Future<ProductVisionResult?> show(
    BuildContext context, {
    required XFile imageFile,
    required List<String> categories,
    List<Product>? existingProducts,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    if (isDesktop) {
      return showDialog<ProductVisionResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
            child: ProductVisionScanningModal(
              imageFile: imageFile,
              categories: categories,
              existingProducts: existingProducts,
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<ProductVisionResult>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.88,
          child: ProductVisionScanningModal(
            imageFile: imageFile,
            categories: categories,
            existingProducts: existingProducts,
          ),
        ),
      );
    }
  }

  @override
  State<ProductVisionScanningModal> createState() =>
      _ProductVisionScanningModalState();
}

class _ProductVisionScanningModalState extends State<ProductVisionScanningModal>
    with TickerProviderStateMixin {
  late final AnimationController _laserController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  String _displayPath = '';
  int _currentPhase = 0;
  bool _cancelled = false;
  ProductVisionResult? _resolvedResult;
  String? _errorMessage;

  static const _phaseLabels = [
    'Analyzing packaging & label...',
    'Extracting part specifications...',
    'Matching motorcycle catalog...',
  ];

  static const _phaseIcons = [
    Icons.filter_center_focus_rounded,
    Icons.document_scanner_rounded,
    Icons.two_wheeler_rounded,
  ];

  @override
  void initState() {
    super.initState();

    // Laser sweeps up and down
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Target reticle pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Smooth overall progress
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _progressController.addListener(() {
      final val = _progressController.value;
      final phase = (val * 3).floor().clamp(0, 2);
      if (phase != _currentPhase && mounted) {
        setState(() => _currentPhase = phase);
      }
    });

    _prepareDisplayPath();
    _startScanPipeline();
  }

  Future<void> _prepareDisplayPath() async {
    if (kIsWeb || widget.imageFile.path.isEmpty) {
      final bytes = await widget.imageFile.readAsBytes();
      if (mounted) {
        setState(() {
          _displayPath = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } else {
      setState(() {
        _displayPath = widget.imageFile.path;
      });
    }
  }

  Future<void> _startScanPipeline() async {
    final startTime = DateTime.now();

    try {
      final result = await ProductVisionService.parseImage(
        widget.imageFile,
        availableCategories: widget.categories,
        existingProducts: widget.existingProducts,
      );

      _resolvedResult = result;
    } catch (e) {
      debugPrint('Scanning pipeline error: $e');
      _errorMessage = 'Scanning error: $e';
    }

    // Ensure user sees the scanning animation for at least 2.2 seconds
    final elapsed = DateTime.now().difference(startTime);
    const minDisplay = Duration(milliseconds: 2200);
    if (elapsed < minDisplay) {
      await Future.delayed(minDisplay - elapsed);
    }

    if (!mounted || _cancelled) return;

    if (_errorMessage != null && _resolvedResult == null) {
      Navigator.of(context).pop(null);
    } else {
      Navigator.of(context).pop(_resolvedResult);
    }
  }

  @override
  void dispose() {
    _cancelled = true;
    _laserController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _cancelled = true;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(28),
            bottom: isDesktop ? const Radius.circular(28) : Radius.zero,
          ),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
          children: [
            // Top grab handle (mobile only)
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
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
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
                        Row(
                          children: [
                            Text(
                              'AI Optical Scanner',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            _LiveBadge(),
                          ],
                        ),
                        Text(
                          'Detecting motorcycle part details & packaging text',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () {
                      _cancelled = true;
                      Navigator.of(context).pop(null);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Main Scanning Viewport
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  children: [
                    // The Image with Holographic HUD & Laser Overlay
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.active.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.active.withValues(alpha: 0.12),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. Scanned Image
                              if (_displayPath.isNotEmpty)
                                AppImage(
                                  imagePath: _displayPath,
                                  fit: BoxFit.cover,
                                )
                              else
                                const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.active,
                                  ),
                                ),

                              // 2. Dark vignette for laser contrast
                              Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 1.1,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.55),
                                    ],
                                  ),
                                ),
                              ),

                              // 3. Cyber Scanning Grid Overlay
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) => CustomPaint(
                                  painter: _ScanningGridPainter(
                                    opacity: 0.18 +
                                        (_pulseController.value * 0.12),
                                  ),
                                ),
                              ),

                              // 4. Futuristic HUD Corner Reticles
                              const CustomPaint(
                                painter: _HudCornerPainter(
                                  color: AppColors.active,
                                ),
                              ),

                              // 5. Pulsing Feature Detection Reticle
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) => CustomPaint(
                                  painter: _TargetReticlePainter(
                                    progress: _pulseController.value,
                                    color: AppColors.active,
                                  ),
                                ),
                              ),

                              // 6. Animated Scanning Laser Beam
                              AnimatedBuilder(
                                animation: _laserController,
                                builder: (context, _) => CustomPaint(
                                  painter: _LaserBeamPainter(
                                    position: _laserController.value,
                                    color: AppColors.active,
                                    accentColor: AppColors.accent,
                                  ),
                                ),
                              ),

                              // 7. Dynamic Detection Status Badges
                              Positioned(
                                top: 12,
                                left: 12,
                                child: _PhaseBadge(
                                  label: _currentPhase >= 0
                                      ? 'OCR MATRIX ACTIVE'
                                      : 'INITIALIZING',
                                  active: true,
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: _PhaseBadge(
                                  label: _currentPhase >= 1
                                      ? 'SPECS LOCATED'
                                      : 'SEEKING LABELS',
                                  active: _currentPhase >= 1,
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: _PhaseBadge(
                                  label: _currentPhase >= 2
                                      ? 'CATALOG MATCHED'
                                      : 'AI INFERENCE',
                                  active: _currentPhase >= 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Progress Status Bar & Stages
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active Phase Info
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.active.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _phaseIcons[_currentPhase],
                                  color: AppColors.active,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _phaseLabels[_currentPhase],
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, _) => Text(
                                  '${(_progressController.value * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: AppColors.active,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Linear Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, _) => LinearProgressIndicator(
                                value: _progressController.value,
                                minHeight: 6,
                                backgroundColor:
                                    AppColors.border.withValues(alpha: 0.6),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.active),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // 3 Small Step Pills
                          Row(
                            children: List.generate(3, (index) {
                              final isCompleted = _currentPhase > index;
                              final isCurrent = _currentPhase == index;
                              return Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                      right: index < 2 ? 6.0 : 0.0),
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? AppColors.active
                                        : isCurrent
                                            ? AppColors.active
                                                .withValues(alpha: 0.7)
                                            : AppColors.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Cancel Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _cancelled = true;
                    Navigator.of(context).pop(null);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Cancel Scan',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

/// Pulsing "SCANNING" status badge in header.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.active.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.active.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.active,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'SCANNING',
            style: TextStyle(
              color: AppColors.active,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating status badges on the image during scanning.
class _PhaseBadge extends StatelessWidget {
  final String label;
  final bool active;

  const _PhaseBadge({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? Colors.black.withValues(alpha: 0.75)
            : Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active
              ? AppColors.active.withValues(alpha: 0.7)
              : Colors.white24,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 10,
            color: active ? AppColors.active : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws futuristic corner brackets around the viewport.
class _HudCornerPainter extends CustomPainter {
  final Color color;

  const _HudCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const cornerLength = 24.0;
    const padding = 12.0;

    // Top-Left
    final pathTL = Path()
      ..moveTo(padding, padding + cornerLength)
      ..lineTo(padding, padding)
      ..lineTo(padding + cornerLength, padding);
    canvas.drawPath(pathTL, paint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(size.width - padding - cornerLength, padding)
      ..lineTo(size.width - padding, padding)
      ..lineTo(size.width - padding, padding + cornerLength);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(padding, size.height - padding - cornerLength)
      ..lineTo(padding, size.height - padding)
      ..lineTo(padding + cornerLength, size.height - padding);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(size.width - padding - cornerLength, size.height - padding)
      ..lineTo(size.width - padding, size.height - padding)
      ..lineTo(size.width - padding, size.height - padding - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the animated horizontal laser beam and trailing sweep.
class _LaserBeamPainter extends CustomPainter {
  final double position; // 0.0 to 1.0
  final Color color;
  final Color accentColor;

  const _LaserBeamPainter({
    required this.position,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * position;

    // Trailing gradient glow
    const trailHeight = 40.0;
    final trailRect = Rect.fromLTRB(0, y - trailHeight, size.width, y);
    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.18),
        ],
      ).createShader(trailRect);
    canvas.drawRect(trailRect, trailPaint);

    // Main laser core line
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.9),
          Colors.white,
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTRB(0, y - 2, size.width, y + 2))
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // Laser glow blur
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _LaserBeamPainter oldDelegate) =>
      oldDelegate.position != position;
}

/// Subtle cyber grid pattern across the scanning area.
class _ScanningGridPainter extends CustomPainter {
  final double opacity;

  const _ScanningGridPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.active.withValues(alpha: opacity)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    const step = 28.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanningGridPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

/// Target reticle that pulses in the center of the image area.
class _TargetReticlePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;

  const _TargetReticlePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.48);

    // Expanding pulse circle
    final radius = 28.0 + (progress * 14.0);
    final pulsePaint = Paint()
      ..color = color.withValues(alpha: (1.0 - progress) * 0.5)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, pulsePaint);

    // Inner fixed circle
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 14.0, innerPaint);

    // Center crosshair dots
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, dotPaint);

    // Reticle crosshair ticks
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.2;

    canvas.drawLine(
        Offset(center.dx - 22, center.dy), Offset(center.dx - 16, center.dy), tickPaint);
    canvas.drawLine(
        Offset(center.dx + 16, center.dy), Offset(center.dx + 22, center.dy), tickPaint);
    canvas.drawLine(
        Offset(center.dx, center.dy - 22), Offset(center.dx, center.dy - 16), tickPaint);
    canvas.drawLine(
        Offset(center.dx, center.dy + 16), Offset(center.dx, center.dy + 22), tickPaint);
  }

  @override
  bool shouldRepaint(covariant _TargetReticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
