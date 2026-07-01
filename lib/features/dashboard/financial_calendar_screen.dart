import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import 'business_calendar_screen.dart';
import 'reports_screen.dart';

class FinancialCalendarScreen extends ConsumerStatefulWidget {
  const FinancialCalendarScreen({super.key});

  @override
  ConsumerState<FinancialCalendarScreen> createState() => _FinancialCalendarScreenState();
}

class _FinancialCalendarScreenState extends ConsumerState<FinancialCalendarScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;
  Set<String> _closedDates = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final list = prefs.getStringList('calendar_closed_dates') ?? [];
      _closedDates = list.toSet();
    });
  }

  bool _isClosed(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _closedDates.contains(dateStr);
  }

  String _formatCompact(double value) {
    if (value >= 1000) {
      return '₱${(value / 1000).toStringAsFixed(1)}k';
    }
    return '₱${value.toStringAsFixed(0)}';
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch sales and expenses
    final includeUnpaid = ref
            .watch(businessSettingsStreamProvider)
            .value
            ?.includeUnpaidInReports ??
        true;
    final sales = (ref.watch(saleListStreamProvider).value ?? [])
        .where((s) => includeUnpaid || s.status != 'unpaid')
        .toList();
    final expenses = ref.watch(expenseListStreamProvider).value ?? [];

    // Filter data for the selected month
    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

    final monthSales = sales.where((s) => !s.createdAt.isBefore(monthStart) && s.createdAt.isBefore(monthEnd)).toList();
    final monthExpenses = expenses.where((e) => !e.createdAt.isBefore(monthStart) && e.createdAt.isBefore(monthEnd)).toList();

    // Summary calculations
    final revenue = monthSales.fold<double>(0, (sum, s) => sum + s.total);
    final cogs = monthSales.fold<double>(
      0,
      (sum, s) => sum + s.items.fold<double>(0.0, (i, it) => i + it.unitCost * it.quantity),
    );
    final grossProfit = revenue - cogs;
    final expenseTotal = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final netProfit = grossProfit - expenseTotal;
    final margin = revenue == 0 ? 0.0 : (grossProfit / revenue) * 100;

    // Days in selected month
    final totalDays = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    int closedCount = 0;
    for (int d = 1; d <= totalDays; d++) {
      if (_isClosed(DateTime(_selectedMonth.year, _selectedMonth.month, d))) {
        closedCount++;
      }
    }
    final operatingDays = totalDays - closedCount;
    final salesPerDay = totalDays == 0 ? 0.0 : monthSales.length / totalDays;

    // Calendar grid computations
    final padding = monthStart.weekday % 7; // Sunday=0 padding
    final totalGridCells = padding + totalDays;
    final endPadding = (7 - (totalGridCells % 7)) % 7;

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
              'Financial calendar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 2x2 Grid of Metrics Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              // Revenue
              _buildMetricCard(
                label: 'REVENUE',
                value: _formatCompact(revenue),
                subtext: '$operatingDays operating days',
                chipColor: const Color(0xFF4ADE80),
                valueColor: const Color(0xFF4ADE80),
                isDark: isDark,
              ),
              // Gross Profit
              _buildMetricCard(
                label: 'GROSS PROFIT',
                value: _formatCompact(grossProfit),
                subtext: '${margin.toStringAsFixed(1)}% margin',
                chipColor: const Color(0xFF38BDF8),
                valueColor: const Color(0xFF38BDF8),
                isDark: isDark,
              ),
              // Net Profit
              _buildMetricCard(
                label: 'NET PROFIT',
                value: _formatCompact(netProfit),
                subtext: netProfit > 0 ? 'Profitable' : (netProfit < 0 ? 'Loss' : 'Breakeven'),
                chipColor: const Color(0xFFA78BFA),
                valueColor: const Color(0xFFA78BFA),
                isDark: isDark,
              ),
              // Total Sales
              _buildMetricCard(
                label: 'TOTAL SALES',
                value: '${monthSales.length}',
                subtext: '${salesPerDay.toStringAsFixed(1)}/day',
                chipColor: const Color(0xFFF59E0B),
                valueColor: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Month selector row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                  });
                },
              ),
              Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
                      });
                    },
                    child: Text(
                      'tap to jump to today',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calendar Heatmap Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
            ),
            child: Column(
              children: [
                // Weekday Headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // Calendar Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: padding + totalDays + endPadding,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (ctx, index) {
                    if (index < padding || index >= padding + totalDays) {
                      return const SizedBox.shrink();
                    }

                    final day = index - padding + 1;
                    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
                    final now = DateTime.now();
                    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

                    // Filter sales for this day
                    final daySales = monthSales.where((s) => s.createdAt.day == day).toList();
                    final dayRevenue = daySales.fold<double>(0, (sum, s) => sum + s.total);
                    final isClosed = _isClosed(date);

                    // Colors based on revenue volume
                    Color cellColor;
                    Color textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;

                    if (isClosed) {
                      cellColor = const Color(0xFF7F1D1D).withValues(alpha: 0.4); // Dark Red
                    } else if (daySales.isEmpty) {
                      cellColor = isDark ? AppColors.bgSurface2 : AppColors.bgSurface2Light;
                      textColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
                    } else if (dayRevenue > 8000) {
                      cellColor = const Color(0xFF059669); // High green
                    } else if (dayRevenue > 3000) {
                      cellColor = const Color(0xFF10B981).withValues(alpha: 0.7); // Medium green
                    } else {
                      cellColor = const Color(0xFF3B82F6).withValues(alpha: 0.6); // Low blue
                    }

                    final isSelected = _selectedDate == date;

                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportsScreen(initialDate: date),
                            ),
                          );
                        } else {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2.5)
                              : isToday
                                  ? Border.all(color: const Color(0xFF3B82F6), width: 2)
                                  : Border.all(
                                      color: isDark ? AppColors.border : AppColors.borderLight,
                                      width: 0.5,
                                    ),
                        ),
                        child: Stack(
                          children: [
                            // Day Number & Today indicator
                            Positioned(
                              top: 4,
                              left: 6,
                              child: Row(
                                children: [
                                  Text(
                                    '$day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  if (isToday) ...[
                                    const SizedBox(width: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text(
                                        'T',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Profit/Revenue data
                            if (!isClosed && daySales.isNotEmpty)
                              Positioned(
                                bottom: 4,
                                left: 4,
                                right: 4,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatCompact(dayRevenue),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 8,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 1),
                                        Text(
                                          '${daySales.length}',
                                          style: const TextStyle(
                                            fontSize: 8,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Legend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('High', const Color(0xFF059669), isDark),
              _buildLegendItem('Medium', const Color(0xFF10B981).withValues(alpha: 0.7), isDark),
              _buildLegendItem('Low', const Color(0xFF3B82F6).withValues(alpha: 0.6), isDark),
              _buildLegendItem('No sales', isDark ? AppColors.bgSurface2 : AppColors.bgSurface2Light, isDark),
              _buildLegendItem('Closed', const Color(0xFF7F1D1D).withValues(alpha: 0.6), isDark),
            ],
          ),
          const SizedBox(height: 24),

          // Bottom Settings Button
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Color(0xFF4ADE80)),
              title: const Text('Mark closed days in Business Calendar'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BusinessCalendarScreen()),
                );
                _loadSettings();
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subtext,
    required Color chipColor,
    required Color valueColor,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: chipColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
