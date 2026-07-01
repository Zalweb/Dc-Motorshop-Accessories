import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../data/models/sale.dart';

// Period selector enum
enum DashboardPeriod { today, yesterday, week, month, custom }

/// Which period the dashboard is showing.
class _PeriodNotifier extends Notifier<DashboardPeriod> {
  @override
  DashboardPeriod build() => DashboardPeriod.today;
  void set(DashboardPeriod p) => state = p;
}

final dashboardPeriodProvider =
    NotifierProvider<_PeriodNotifier, DashboardPeriod>(_PeriodNotifier.new);

/// Date range used when [DashboardPeriod.custom] is selected.
class _RangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
  void set(DateTimeRange? r) => state = r;
}

final dashboardCustomRangeProvider =
    NotifierProvider<_RangeNotifier, DateTimeRange?>(_RangeNotifier.new);

/// Derived business metrics for the dashboard.
class DashboardSummary {
  const DashboardSummary({
    required this.revenue,
    required this.salesCount,
    required this.cogs,
    required this.grossProfit,
    required this.expenses,
    required this.netProfit,
    required this.discount,
    required this.avgTicket,
    required this.grossMargin,
    required this.chartData,
    required this.periodLabel,
    required this.totalItemsSold,
    required this.lowStockCount,
  });

  final double revenue;
  final int salesCount;
  final double cogs;
  final double grossProfit;
  final double expenses;
  final double netProfit;
  final double discount;
  final double avgTicket;
  final double grossMargin;
  final int totalItemsSold;
  final int lowStockCount;

  /// Revenue data points for the line chart, synced to the selected period:
  ///  - Single day  → 3 points: [day-2, day-1, selected day]
  ///  - Date range  → one point per day in the range
  final List<double> chartData;

  /// Human-readable period label shown in the revenue hero card.
  final String periodLabel;

  static final empty = DashboardSummary(
    revenue: 0,
    salesCount: 0,
    cogs: 0,
    grossProfit: 0,
    expenses: 0,
    netProfit: 0,
    discount: 0,
    avgTicket: 0,
    grossMargin: 0,
    chartData: [0, 0, 0],
    periodLabel: 'Today',
    totalItemsSold: 0,
    lowStockCount: 0,
  );
}

String _fmtDate(DateTime d) => DateFormat('MMM d').format(d);

/// Revenue total for a single calendar day.
double _dayRevenue(List<Sale> sales, DateTime dayStart) {
  final dayEnd = dayStart.add(const Duration(days: 1));
  return sales.fold<double>(
    0.0,
    (sum, s) {
      return !s.createdAt.isBefore(dayStart) && s.createdAt.isBefore(dayEnd)
          ? sum + s.total
          : sum;
    },
  );
}

/// Recomputes whenever sales, expenses, or the period selection change.
final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final includeUnpaid = ref
          .watch(businessSettingsStreamProvider)
          .value
          ?.includeUnpaidInReports ??
      true;
  final sales = (ref.watch(saleListStreamProvider).value ?? [])
      .where((s) => includeUnpaid || s.status != 'unpaid')
      .toList();
  final expenses = ref.watch(expenseListStreamProvider).value ?? [];
  final products = ref.watch(productListStreamProvider).value ?? [];
  final period = ref.watch(dashboardPeriodProvider);
  final customRange = ref.watch(dashboardCustomRangeProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Resolve current period bounds and chart data.
  late DateTime start;
  late DateTime end; // exclusive
  late String periodLabel;
  late List<double> chartData;

  // Monday-based start of the calendar week containing [d].
  DateTime weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - DateTime.monday));

  if (period == DashboardPeriod.today) {
    start = today;
    end = today.add(const Duration(days: 1));
    periodLabel = 'Today';
    chartData = [
      _dayRevenue(sales, today.subtract(const Duration(days: 2))),
      _dayRevenue(sales, today.subtract(const Duration(days: 1))),
      _dayRevenue(sales, today),
    ];
  } else if (period == DashboardPeriod.yesterday) {
    final yesterday = today.subtract(const Duration(days: 1));
    start = yesterday;
    end = today;
    periodLabel = 'Yesterday';
    chartData = [
      _dayRevenue(sales, today.subtract(const Duration(days: 3))),
      _dayRevenue(sales, today.subtract(const Duration(days: 2))),
      _dayRevenue(sales, yesterday),
    ];
  } else if (period == DashboardPeriod.week) {
    start = weekStart(today);
    end = start.add(const Duration(days: 7));
    periodLabel = 'This Week';
    chartData = List.generate(7, (i) => _dayRevenue(sales, start.add(Duration(days: i))));
  } else if (period == DashboardPeriod.month) {
    start = DateTime(now.year, now.month, 1);
    end = DateTime(now.year, now.month + 1, 1);
    periodLabel = 'This Month';
    final days = end.difference(start).inDays;
    chartData = List.generate(days, (i) => _dayRevenue(sales, start.add(Duration(days: i))));
  } else if (customRange != null) {
    start = DateTime(
        customRange.start.year, customRange.start.month, customRange.start.day);
    end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day)
        .add(const Duration(days: 1));

    final days = end.difference(start).inDays;

    if (days == 1) {
      periodLabel = _fmtDate(customRange.start);
      chartData = [
        _dayRevenue(sales, start.subtract(const Duration(days: 2))),
        _dayRevenue(sales, start.subtract(const Duration(days: 1))),
        _dayRevenue(sales, start),
      ];
    } else {
      periodLabel =
          '${_fmtDate(customRange.start)} – ${_fmtDate(customRange.end)}';
      chartData = List.generate(days, (i) => _dayRevenue(sales, start.add(Duration(days: i))));
    }
  } else {
    // Custom selected but no range picked yet — fall back to today.
    start = today;
    end = today.add(const Duration(days: 1));
    periodLabel = 'Today';
    chartData = [
      _dayRevenue(sales, today.subtract(const Duration(days: 2))),
      _dayRevenue(sales, today.subtract(const Duration(days: 1))),
      _dayRevenue(sales, today),
    ];
  }

  bool inPeriod(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  final periodSales = sales.where((s) => inPeriod(s.createdAt)).toList();
  final periodExpenses = expenses.where((e) => inPeriod(e.createdAt)).toList();

  final revenue =
      periodSales.fold<double>(0, (sum, s) => sum + s.total);
  final discount =
      periodSales.fold<double>(0, (sum, s) => sum + s.discount);
  final cogs = periodSales.fold<double>(
    0,
    (sum, s) =>
        sum + s.items.fold<double>(0.0, (i, it) => i + it.unitCost * it.quantity),
  );
  final expenseTotal =
      periodExpenses.fold<double>(0, (sum, e) => sum + e.amount);

  final grossProfit = revenue - cogs;
  final netProfit = grossProfit - expenseTotal;
  final avgTicket =
      periodSales.isEmpty ? 0.0 : revenue / periodSales.length;
  final grossMargin =
      revenue == 0 ? 0.0 : (grossProfit / revenue) * 100;

  final totalItemsSold = periodSales.fold<int>(
    0,
    (sum, s) => sum + s.items.fold<int>(0, (i, it) => i + it.quantity),
  );

  final lowStockCount = products.where((p) => !p.isService && p.stockQty <= 5).length;

  return DashboardSummary(
    revenue: revenue,
    salesCount: periodSales.length,
    cogs: cogs,
    grossProfit: grossProfit,
    expenses: expenseTotal,
    netProfit: netProfit,
    discount: discount,
    avgTicket: avgTicket,
    grossMargin: grossMargin,
    chartData: chartData,
    periodLabel: periodLabel,
    totalItemsSold: totalItemsSold,
    lowStockCount: lowStockCount,
  );
});
