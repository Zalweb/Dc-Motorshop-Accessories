import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/glass_container.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const ReportsScreen({super.key, this.initialDate});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late String _choice; // 'today', 'yesterday', '7d', 'custom'
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _choice = 'custom';
      _customRange = DateTimeRange(
        start: widget.initialDate!,
        end: widget.initialDate!,
      );
    } else {
      _choice = 'today';
    }
  }

  String _formatPeso(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _formatCompact(double value) {
    if (value >= 1000) {
      return '₱${(value / 1000).toStringAsFixed(1)}k';
    }
    return '₱${value.toStringAsFixed(0)}';
  }

  Future<void> _selectCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _customRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );
    if (picked != null) {
      if (picked.end.difference(picked.start).inDays > 365) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Date range cannot exceed 1 year')),
          );
        }
        return;
      }
      setState(() {
        _choice = 'custom';
        _customRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    // Watch sales, products, and expenses
    final includeUnpaid = ref
            .watch(businessSettingsStreamProvider)
            .value
            ?.includeUnpaidInReports ??
        true;
    final sales = (ref.watch(saleListStreamProvider).value ?? [])
        .where((s) => includeUnpaid || s.status != 'unpaid')
        .toList();
    final products = ref.watch(productListStreamProvider).value ?? [];
    final expenses = ref.watch(expenseListStreamProvider).value ?? [];

    // Build lookup maps: by local int id AND by uid (cloud-synced items only have uid)
    final productMap = {for (final p in products) p.id: p};
    final productMapByUid = {for (final p in products) p.uid: p};

    // Resolve date boundaries based on choice
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    late DateTime start;
    late DateTime end;

    if (_choice == 'today') {
      start = today;
      end = today.add(const Duration(days: 1));
    } else if (_choice == 'yesterday') {
      start = today.subtract(const Duration(days: 1));
      end = today;
    } else if (_choice == '7d') {
      start = today.subtract(const Duration(days: 6));
      end = today.add(const Duration(days: 1));
    } else {
      if (_customRange != null) {
        start = DateTime(_customRange!.start.year, _customRange!.start.month, _customRange!.start.day);
        end = DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day).add(const Duration(days: 1));
      } else {
        // Fallback
        start = today.subtract(const Duration(days: 6));
        end = today.add(const Duration(days: 1));
      }
    }

    final durationDays = end.difference(start).inDays;

    // Filter sales & expenses
    final periodSales = sales.where((s) => !s.createdAt.isBefore(start) && s.createdAt.isBefore(end)).toList();
    final periodExpenses = expenses.where((e) => !e.createdAt.isBefore(start) && e.createdAt.isBefore(end)).toList();

    // Summary calculations
    final revenue = periodSales.fold<double>(0, (sum, s) => sum + s.total);
    final cogs = periodSales.fold<double>(
      0,
      (sum, s) => sum + s.items.fold<double>(0.0, (i, it) => i + it.unitCost * it.quantity),
    );
    final grossProfit = revenue - cogs;
    final expenseTotal = periodExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final netProfit = grossProfit - expenseTotal;
    
    final discount = periodSales.fold<double>(0, (sum, s) => sum + s.discount);
    final avgTicket = periodSales.isEmpty ? 0.0 : revenue / periodSales.length;

    final grossMargin = revenue == 0 ? 0.0 : (grossProfit / revenue) * 100;
    final netMargin = revenue == 0 ? 0.0 : (netProfit / revenue) * 100;

    // Generate trend chart data (daily revenue)
    final trendPoints = <double>[];
    for (int i = 0; i < durationDays; i++) {
      final dayStart = start.add(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayRev = sales
          .where((s) => !s.createdAt.isBefore(dayStart) && s.createdAt.isBefore(dayEnd))
          .fold<double>(0, (sum, s) => sum + s.total);
      trendPoints.add(dayRev);
    }
    // Ensure we have at least 2 points for drawing
    if (trendPoints.length < 2) {
      trendPoints.insert(0, 0.0);
    }

    // Day of Week pattern calculation (Mon=1, Sun=7)
    final dayRevenue = List<double>.filled(7, 0.0);
    for (final sale in periodSales) {
      final wd = sale.createdAt.weekday;
      dayRevenue[wd - 1] += sale.total;
    }
    final maxWdRevenue = dayRevenue.reduce((a, b) => a > b ? a : b);
    final maxWdIndex = maxWdRevenue > 0 ? dayRevenue.indexOf(maxWdRevenue) : -1;

    // Top Products aggregation
    final productStats = <String, (double, int)>{}; // name -> (revenue, qty)
    for (final sale in periodSales) {
      for (final item in sale.items) {
        final current = productStats[item.name] ?? (0.0, 0);
        productStats[item.name] = (current.$1 + item.lineTotal, current.$2 + item.quantity);
      }
    }
    final sortedProducts = productStats.entries
        .map((e) => _ProductStat(name: e.key, revenue: e.value.$1, qtySold: e.value.$2))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    // Top Categories aggregation
    final categoryStats = <String, (double, int)>{}; // category -> (revenue, qty)
    for (final sale in periodSales) {
      for (final item in sale.items) {
        // Look up by uid first (cloud-synced), fall back to local int id
        final cat = (productMapByUid[item.productUid] ?? productMap[item.productId])?.category ?? 'Uncategorized';
        final current = categoryStats[cat] ?? (0.0, 0);
        categoryStats[cat] = (current.$1 + item.lineTotal, current.$2 + item.quantity);
      }
    }
    final sortedCategories = categoryStats.entries
        .map((e) => _ProductStat(name: e.key, revenue: e.value.$1, qtySold: e.value.$2))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgBase : AppColors.bgBaseLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgBase : AppColors.bgBaseLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Reports',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              _choice == 'custom' && _customRange != null
                  ? '${DateFormat('MMMd').format(_customRange!.start)} – ${DateFormat('MMMd, yyyy').format(_customRange!.end)}'
                  : (_choice == 'today'
                      ? 'Today'
                      : (_choice == 'yesterday'
                          ? 'Yesterday'
                          : 'Last 7 Days')),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Period selector pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodPill('Today', _choice == 'today', () {
                  setState(() => _choice = 'today');
                }),
                const SizedBox(width: 8),
                _buildPeriodPill('Yesterday', _choice == 'yesterday', () {
                  setState(() => _choice = 'yesterday');
                }),
                const SizedBox(width: 8),
                _buildPeriodPill('7D', _choice == '7d', () {
                  setState(() => _choice = '7d');
                }),
                const SizedBox(width: 8),
                _buildPeriodPill(
                  _choice == 'custom' && _customRange != null
                      ? '${DateFormat('MMMd').format(_customRange!.start)}-${DateFormat('MMMd').format(_customRange!.end)}'
                      : 'Custom',
                  _choice == 'custom',
                  _selectCustomRange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Revenue Card with branding gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary.withValues(alpha: 0.9),
                  secondary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REVENUE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _formatPeso(revenue),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Sparkline
                    SizedBox(
                      width: 100,
                      height: 50,
                      child: Sparkline(
                        data: trendPoints,
                        lineColor: Colors.white,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${periodSales.length} sales  •  ${_formatPeso(avgTicket)} avg',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // PROFIT & LOSS section
          Text(
            'PROFIT & LOSS',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildPLCard(
                label: 'GROSS PROFIT',
                value: _formatPeso(grossProfit),
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
              _buildPLCard(
                label: 'NET PROFIT',
                value: _formatPeso(netProfit),
                icon: Icons.insert_chart_outlined,
                color: const Color(0xFF4ADE80),
                isDark: isDark,
              ),
              _buildPLCard(
                label: 'COST OF GOODS',
                value: _formatPeso(cogs),
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF2DD4BF),
                isDark: isDark,
              ),
              _buildPLCard(
                label: 'EXPENSES',
                value: _formatPeso(expenseTotal),
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Financial Lists
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                _buildRowItem('AVG TICKET', _formatPeso(avgTicket), Icons.assignment_outlined, const Color(0xFFF59E0B), isDark),
                Divider(color: isDark ? AppColors.border : AppColors.borderLight, height: 1),
                _buildRowItem('DISCOUNT', _formatPeso(discount), Icons.label_outline, const Color(0xFFA78BFA), isDark),
                Divider(color: isDark ? AppColors.border : AppColors.borderLight, height: 1),
                _buildRowItem('GROSS MARGIN', '${grossMargin.toStringAsFixed(1)}%', Icons.show_chart, const Color(0xFF10B981), isDark),
                Divider(color: isDark ? AppColors.border : AppColors.borderLight, height: 1),
                _buildRowItem('NET MARGIN', '${netMargin.toStringAsFixed(1)}%', Icons.trending_up, const Color(0xFF38BDF8), isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // BY DAY OF WEEK section
          Text(
            'BY DAY OF WEEK',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
            ),
            child: SizedBox(
              height: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final rev = dayRevenue[i];
                  final isMax = i == maxWdIndex;
                  final heightRatio = maxWdRevenue > 0 ? (rev / maxWdRevenue) : 0.0;
                  final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          rev > 0 ? _formatCompact(rev) : '—',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isMax ? FontWeight.bold : FontWeight.normal,
                            color: isMax
                                ? primary
                                : (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: heightRatio * 70 + 8, // Min height 8 for visible bar
                          width: 14,
                          decoration: BoxDecoration(
                            color: isMax
                                ? primary
                                : (isDark ? AppColors.bgSurface2 : AppColors.bgSurface2Light),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isMax ? '★ ${weekdays[i]}' : weekdays[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isMax ? FontWeight.bold : FontWeight.normal,
                            color: isMax
                                ? primary
                                : (isDark ? AppColors.textMuted : AppColors.textMutedLight),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // TOP PRODUCTS section
          Text(
            'TOP PRODUCTS',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (sortedProducts.isEmpty)
            _buildEmptyBlock('No products sold in this range', isDark)
          else
            Column(
              children: List.generate(
                sortedProducts.length.clamp(0, 5),
                (i) => _buildTopStatRow(
                  rank: i + 1,
                  name: sortedProducts[i].name,
                  revenue: sortedProducts[i].revenue,
                  subtext: '${sortedProducts[i].qtySold} sold',
                  maxRevenue: sortedProducts[0].revenue,
                  icon: Icons.inventory_2_outlined,
                  isDark: isDark,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // TOP CATEGORIES section
          Text(
            'TOP CATEGORIES',
            style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (sortedCategories.isEmpty)
            _buildEmptyBlock('No categories sold in this range', isDark)
          else
            Column(
              children: List.generate(
                sortedCategories.length.clamp(0, 5),
                (i) => _buildTopStatRow(
                  rank: i + 1,
                  name: sortedCategories[i].name,
                  revenue: sortedCategories[i].revenue,
                  subtext: '${sortedCategories[i].qtySold} items',
                  maxRevenue: sortedCategories[0].revenue,
                  icon: Icons.folder_open_outlined,
                  isDark: isDark,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPeriodPill(String label, bool selected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? primary
                : (isDark ? AppColors.border : AppColors.borderLight),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? primary
                : (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPLCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowItem(String label, String value, IconData icon, Color iconColor, bool isDark) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildTopStatRow({
    required int rank,
    required String name,
    required double revenue,
    required String subtext,
    required double maxRevenue,
    required IconData icon,
    required bool isDark,
  }) {
    final progress = maxRevenue > 0 ? (revenue / maxRevenue) : 0.0;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Rank Indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Icon
          Icon(icon, size: 18, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
          const SizedBox(width: 12),
          // Name and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 5,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark ? AppColors.bgSurface2 : AppColors.bgSurface2Light,
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Price and subtext
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCompact(revenue),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBlock(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ProductStat {
  final String name;
  final double revenue;
  final int qtySold;
  _ProductStat({required this.name, required this.revenue, required this.qtySold});
}

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(data, lineColor, fillColor),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.data, this.lineColor, this.fillColor);

  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final path = Path();
    final fillPath = Path();

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final stepX = size.width / (data.length - 1 == 0 ? 1 : data.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minVal) / range) * (size.height * 0.7) - (size.height * 0.15);
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlX = p1.dx + (p2.dx - p1.dx) / 2;
      path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
      fillPath.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillColor.withValues(alpha: 0.4), fillColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.lineColor != lineColor || oldDelegate.fillColor != fillColor;
}
