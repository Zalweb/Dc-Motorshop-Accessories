import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutSlice {
  const DonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// A clean, modern donut ring chart with segment gaps and optional center widget.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.size = 140,
    this.strokeWidth = 16,
    this.centerWidget,
  });

  final List<DonutSlice> slices;
  final double size;
  final double strokeWidth;
  final Widget? centerWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emptyColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              slices: slices,
              strokeWidth: strokeWidth,
              emptyColor: emptyColor,
            ),
          ),
          ?centerWidget,
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.slices,
    required this.strokeWidth,
    required this.emptyColor,
  });

  final List<DonutSlice> slices;
  final double strokeWidth;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (radius <= 0) return;

    final total = slices.fold<double>(0, (sum, s) => sum + s.value);

    // If empty or all zeros, draw subtle background ring
    if (total <= 0 || slices.isEmpty) {
      final bgPaint = Paint()
        ..color = emptyColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, bgPaint);
      return;
    }

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -math.pi / 2; // Start from top

    // Compute gap between slices if multiple slices exist
    final nonZeroCount = slices.where((s) => s.value > 0).length;
    final gapAngle = nonZeroCount > 1 ? 0.05 : 0.0;
    final totalUsableSweep = 2 * math.pi - (gapAngle * nonZeroCount);

    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweepAngle = (slice.value / total) * totalUsableSweep;

      final paint = Paint()
        ..color = slice.color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) {
    return old.slices != slices ||
        old.strokeWidth != strokeWidth ||
        old.emptyColor != emptyColor;
  }
}
