import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/utils/money.dart';

/// A smooth, high-fidelity line and area gradient chart for revenue overview.
/// Renders cubic Bézier curves, gradient fill, gridlines, axis labels,
/// glowing points, and interactive hover tooltip.
class RevenueAreaChart extends StatefulWidget {
  const RevenueAreaChart({
    super.key,
    required this.values,
    required this.labels,
    this.lineColor = const Color(0xFF2563EB),
    this.height = 220,
  });

  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final double height;

  @override
  State<RevenueAreaChart> createState() => _RevenueAreaChartState();
}

class _RevenueAreaChartState extends State<RevenueAreaChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = widget.values.isEmpty ? <double>[0, 0, 0] : widget.values;
    final labels = widget.labels.isEmpty
        ? List.generate(values.length, (i) => '')
        : widget.labels;

    // Calculate nice max ceiling for Y axis
    final rawMax = values.fold<double>(0, (m, v) => math.max(m, v));
    final double maxY;
    if (rawMax <= 0) {
      maxY = 10000;
    } else if (rawMax < 1000) {
      maxY = ((rawMax / 100).ceil() * 100).toDouble();
    } else if (rawMax < 10000) {
      maxY = ((rawMax / 1000).ceil() * 1000).toDouble();
    } else {
      maxY = ((rawMax / 5000).ceil() * 5000).toDouble();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const leftPadding = 48.0;
        const rightPadding = 16.0;
        const bottomPadding = 24.0;
        const topPadding = 12.0;

        final chartWidth = math.max(0.0, width - leftPadding - rightPadding);
        final chartHeight = math.max(0.0, widget.height - topPadding - bottomPadding);

        return MouseRegion(
          onHover: (event) {
            final x = event.localPosition.dx - leftPadding;
            if (x >= 0 && x <= chartWidth && values.length > 1) {
              final step = chartWidth / (values.length - 1);
              final index = (x / step).round().clamp(0, values.length - 1);
              if (_hoveredIndex != index) {
                setState(() => _hoveredIndex = index);
              }
            }
          },
          onExit: (_) {
            if (_hoveredIndex != null) {
              setState(() => _hoveredIndex = null);
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: width,
                height: widget.height,
                child: CustomPaint(
                  painter: _RevenueAreaChartPainter(
                    values: values,
                    labels: labels,
                    maxY: maxY,
                    lineColor: widget.lineColor,
                    textColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    gridColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
                    hoveredIndex: _hoveredIndex,
                    leftPadding: leftPadding,
                    rightPadding: rightPadding,
                    topPadding: topPadding,
                    bottomPadding: bottomPadding,
                  ),
                ),
              ),

              // Tooltip if hovered
              if (_hoveredIndex != null && _hoveredIndex! < values.length) ...[
                Builder(
                  builder: (context) {
                    final idx = _hoveredIndex!;
                    final step = values.length > 1 ? chartWidth / (values.length - 1) : 0.0;
                    final ptX = leftPadding + (idx * step);
                    final ratio = (values[idx] / maxY).clamp(0.0, 1.0);
                    final ptY = topPadding + chartHeight * (1.0 - ratio);

                    final dateLabel = idx < labels.length ? labels[idx] : '';
                    final amount = formatPeso(values[idx]);

                    return Positioned(
                      left: (ptX - 60).clamp(8.0, width - 130),
                      top: math.max(0.0, ptY - 48),
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.lineColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dateLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                amount,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.lineColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RevenueAreaChartPainter extends CustomPainter {
  const _RevenueAreaChartPainter({
    required this.values,
    required this.labels,
    required this.maxY,
    required this.lineColor,
    required this.textColor,
    required this.gridColor,
    required this.hoveredIndex,
    required this.leftPadding,
    required this.rightPadding,
    required this.topPadding,
    required this.bottomPadding,
  });

  final List<double> values;
  final List<String> labels;
  final double maxY;
  final Color lineColor;
  final Color textColor;
  final Color gridColor;
  final int? hoveredIndex;
  final double leftPadding;
  final double rightPadding;
  final double topPadding;
  final double bottomPadding;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    if (chartWidth <= 0 || chartHeight <= 0 || values.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // 1. Draw 5 horizontal grid lines & Y-axis labels
    const steps = 4;
    for (int i = 0; i <= steps; i++) {
      final yRatio = i / steps;
      final y = topPadding + chartHeight * (1.0 - yRatio);
      final levelValue = maxY * yRatio;

      // Draw gridline
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );

      // Y-axis label text
      final label = _formatYLabel(levelValue);
      final span = TextSpan(text: label, style: textStyle);
      final tp = TextPainter(
        text: span,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPadding - 8);

      tp.paint(canvas, Offset(leftPadding - tp.width - 8, y - tp.height / 2));
    }

    // 2. Compute point coordinates
    final points = <Offset>[];
    final count = values.length;
    final stepX = count > 1 ? chartWidth / (count - 1) : 0.0;

    for (int i = 0; i < count; i++) {
      final x = leftPadding + (i * stepX);
      final ratio = maxY > 0 ? (values[i] / maxY).clamp(0.0, 1.0) : 0.0;
      final y = topPadding + chartHeight * (1.0 - ratio);
      points.add(Offset(x, y));
    }

    // 3. Build smooth Bézier paths
    if (points.isNotEmpty) {
      final linePath = Path();
      linePath.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final midX = (p0.dx + p1.dx) / 2;
        linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      }

      // Area fill path
      final areaPath = Path.from(linePath);
      areaPath.lineTo(points.last.dx, topPadding + chartHeight);
      areaPath.lineTo(points.first.dx, topPadding + chartHeight);
      areaPath.close();

      // Draw Area Gradient
      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.28),
            lineColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight))
        ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, areaPaint);

      // Draw Glow Line
      final glowPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.25)
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, glowPaint);

      // Draw Main Stroke
      final strokePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, strokePaint);

      // 4. Draw data point markers
      for (int i = 0; i < points.length; i++) {
        final pt = points[i];
        final isHovered = hoveredIndex == i;

        // Outer halo
        canvas.drawCircle(
          pt,
          isHovered ? 8.0 : 4.5,
          Paint()..color = lineColor.withValues(alpha: isHovered ? 0.35 : 0.2),
        );

        // Center dot
        canvas.drawCircle(
          pt,
          isHovered ? 4.5 : 3.0,
          Paint()..color = isHovered ? Colors.white : lineColor,
        );
      }
    }

    // 5. Draw X-axis labels
    for (int i = 0; i < labels.length; i++) {
      if (i >= points.length) break;
      final x = points[i].dx;
      final y = topPadding + chartHeight + 8;
      final isHovered = hoveredIndex == i;

      final span = TextSpan(
        text: labels[i],
        style: textStyle.copyWith(
          color: isHovered ? lineColor : textColor,
          fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
        ),
      );
      final tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(x - tp.width / 2, y));
    }
  }

  String _formatYLabel(double val) {
    if (val >= 1000000) {
      return '₱${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      final k = (val / 1000);
      return k % 1 == 0 ? '₱${k.toInt()}K' : '₱${k.toStringAsFixed(1)}K';
    } else {
      return '₱${val.toInt()}';
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueAreaChartPainter old) {
    return old.values != values ||
        old.labels != labels ||
        old.maxY != maxY ||
        old.hoveredIndex != hoveredIndex ||
        old.lineColor != lineColor;
  }
}
