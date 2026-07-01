import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../shared/widgets/brand_mark.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/metric_card.dart';
import 'dashboard_controller.dart';
import '../expenses/expenses_screen.dart';
import 'reports_screen.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' hide Text, Navigator, List;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: ref.read(dashboardCustomRangeProvider) ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 6)),
            end: now,
          ),
    );
    if (range != null) {
      ref.read(dashboardCustomRangeProvider.notifier).set(range);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final period = ref.watch(dashboardPeriodProvider);
    final settings = ref.watch(businessSettingsStreamProvider).value;
    final shopName = settings?.businessName ?? 'DC Motorshop & Accessories';
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Checklist data computed dynamically (matches setup_checklist_screen.dart)
    final productCount = ref.watch(productListStreamProvider).value?.length ?? 0;
    final expenseCount = ref.watch(expenseListStreamProvider).value?.length ?? 0;

    final closedDates = ref.watch(calendarClosedDatesProvider);
    final hasClosedDays = closedDates.isNotEmpty;

    int doneCount = 0;
    if (settings != null) {
      if ((settings.logoPath ?? '').trim().isNotEmpty) doneCount++;
      if ((settings.address ?? '').trim().isNotEmpty && (settings.phone ?? '').trim().isNotEmpty) doneCount++;
      if (productCount > 0) doneCount++;
      if (settings.workflowStages.isNotEmpty) doneCount++;
      if (expenseCount > 0) doneCount++;
      if (hasClosedDays) doneCount++;
    }
    const totalItems = 6;
    final checklistComplete = doneCount >= totalItems;
    final progress = doneCount / totalItems;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            try {
              await ref.read(supabaseSyncServiceProvider).syncNow();
              final prefs = ref.read(sharedPreferencesProvider);
              final dates = prefs.getStringList('calendar_closed_dates') ?? [];
              ref.read(calendarClosedDatesProvider.notifier).set(dates);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sync failed: $e')),
                );
              }
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Header
            Row(
              children: [
                settings?.logoPath != null && settings!.logoPath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: settings.logoPath!.startsWith('http')
                            ? Image.network(
                                settings.logoPath!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const BrandMark(size: 40),
                              )
                            : Image.file(
                                File(settings.logoPath!),
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const BrandMark(size: 40),
                              ),
                      )
                    : const BrandMark(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    shopName,
                    style: AppTextStyles.headingMedium.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Setup Checklist Banner ─────────────────────────────────────
            if (!checklistComplete)
              _SetupBanner(
                progress: progress,
                doneCount: doneCount,
                totalItems: totalItems,
              ),
            if (!checklistComplete) const SizedBox(height: 16),

            // Period selector
            _PeriodSelector(
              selected: period,
              onSelected: (p) {
                ref.read(dashboardPeriodProvider.notifier).set(p);
                if (p == DashboardPeriod.custom) {
                  _pickCustomRange(context, ref);
                }
              },
              customLabel: period == DashboardPeriod.custom
                  ? summary.periodLabel
                  : 'Custom',
            ),
            const SizedBox(height: 16),

            // Revenue hero card
            _RevenueHero(
              revenue: summary.revenue,
              salesCount: summary.salesCount,
              avgTicket: summary.avgTicket,
              chartData: summary.chartData,
              periodLabel: summary.periodLabel,
            ),
            const SizedBox(height: 28),

            Text(
              'AT A GLANCE',
              style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                MetricCard(
                  label: 'Gross Profit',
                  value: formatPeso(summary.grossProfit),
                  icon: Wallet(color: primary, width: 22, height: 22),
                ),
                MetricCard(
                  label: 'Net Profit',
                  value: formatPeso(summary.netProfit),
                  icon: GraphUp(color: primary, width: 22, height: 22),
                ),
                MetricCard(
                  label: 'Cost of Goods',
                  value: formatPeso(summary.cogs),
                  icon: BoxIso(color: primary, width: 22, height: 22),
                ),
                MetricCard(
                  label: 'Expenses',
                  value: summary.expenses == 0
                      ? 'View details'
                      : formatPeso(summary.expenses),
                  icon: PlusSquare(color: primary, width: 22, height: 22),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: _SmallMetricCard(
                    label: 'Items Sold',
                    value: '${summary.totalItemsSold}',
                    icon: Cart(color: primary, width: 18, height: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SmallMetricCard(
                    label: 'Low Stock',
                    value: '${summary.lowStockCount}',
                    icon: Icon(
                      Icons.warning_amber_rounded,
                      color: primary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SmallMetricCard(
                    label: 'Margin',
                    value: '${summary.grossMargin.toStringAsFixed(1)}%',
                    icon: Percentage(color: primary, width: 18, height: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }
}
// ─── Setup Checklist Banner ───────────────────────────────────────────────────
class _SetupBanner extends ConsumerWidget {
  const _SetupBanner({
    required this.progress,
    required this.doneCount,
    required this.totalItems,
  });

  final double progress;
  final int doneCount;
  final int totalItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pct = (progress * 100).round();
    // Color shifts from amber → green as you complete more
    final bannerColor = pct >= 75
        ? const Color(0xFF2E7D32) // dark green
        : pct >= 50
            ? const Color(0xFFF57F17) // amber-dark
            : const Color(0xFFE65100); // deep orange

    return GestureDetector(
      onTap: () => context.push(RoutePaths.setupChecklist),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: bannerColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bannerColor.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist_rounded, size: 18, color: bannerColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Finish setting up your shop',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Percentage badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: bannerColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      color: bannerColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios_rounded, size: 13, color: bannerColor),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: bannerColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(bannerColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$doneCount of $totalItems steps complete — tap to continue',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Period selector ──────────────────────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onSelected,
    required this.customLabel,
  });

  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onSelected;
  final String customLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    String labelFor(DashboardPeriod p) {
      switch (p) {
        case DashboardPeriod.today:
          return 'Today';
        case DashboardPeriod.yesterday:
          return 'Yesterday';
        case DashboardPeriod.week:
          return 'Week';
        case DashboardPeriod.month:
          return 'Month';
        case DashboardPeriod.custom:
          return customLabel;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
      children: DashboardPeriod.values.map((p) {
        final isSelected = selected == p;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelected(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? primary : primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? primary : primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p == DashboardPeriod.custom)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.calendar_month_outlined,
                        size: 13,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    labelFor(p),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
      ),
    );
  }
}

// ─── Revenue hero ─────────────────────────────────────────────────────────────
class _RevenueHero extends StatelessWidget {
  const _RevenueHero({
    required this.revenue,
    required this.salesCount,
    required this.avgTicket,
    required this.chartData,
    required this.periodLabel,
  });

  final double revenue;
  final int salesCount;
  final double avgTicket;
  final List<double> chartData;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primary.withValues(alpha: 0.9),
              secondary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REVENUE \u00b7 ${periodLabel.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              formatPeso(revenue),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$salesCount transactions  \u00b7  ${formatPeso(avgTicket)} avg',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Line chart (no labels)
            SizedBox(
              height: 72,
              child: _RevenueLineChart(data: chartData),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Line chart ───────────────────────────────────────────────────────────────
class _RevenueLineChart extends StatelessWidget {
  const _RevenueLineChart({required this.data});
  final List<double> data;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(data),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.data);
  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.fold<double>(0, (m, v) => v > m ? v : m);

    // Build point list
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : size.width * i / (data.length - 1);
      final y = maxVal == 0
          ? size.height * 0.85
          : size.height - (data[i] / maxVal) * size.height * 0.85;
      points.add(Offset(x, y));
    }

    if (points.length < 2) {
      // Single point – draw a dot + horizontal dashed baseline
      final dot = points.first;
      final basePaint = Paint()
        ..color = Colors.white24
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), basePaint);
      canvas.drawCircle(dot, 5,
          Paint()..color = Colors.white..style = PaintingStyle.fill);
      return;
    }

    // Smooth cubic bezier line path
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final midX = (points[i].dx + points[i + 1].dx) / 2;
      final cp1 = Offset(midX, points[i].dy);
      final cp2 = Offset(midX, points[i + 1].dy);
      linePath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }

    // Gradient fill below the line
    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    // Line stroke
    canvas.drawPath(
      linePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Endpoint dot (last / current data point)
    final dot = points.last;
    canvas.drawCircle(dot, 5.0,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(
      dot,
      5.0,
      Paint()
        ..color = Colors.white54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.data != data;
}

// ─── Small metric card ────────────────────────────────────────────────────────
class _SmallMetricCard extends StatelessWidget {
  const _SmallMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: icon,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
