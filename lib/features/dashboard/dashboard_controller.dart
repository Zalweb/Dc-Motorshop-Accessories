import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/utils/stock_health.dart';
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

class TopSellingItem {
  final String name;
  final int quantity;
  final double totalRevenue;
  final String? imagePath;
  final String? imageUrl;

  const TopSellingItem({
    required this.name,
    required this.quantity,
    required this.totalRevenue,
    this.imagePath,
    this.imageUrl,
  });
}

class PaymentMethodBreakdown {
  final String method;
  final double amount;
  final double percentage;
  final Color color;

  const PaymentMethodBreakdown({
    required this.method,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class TransactionStatusBreakdown {
  final String status;
  final int count;
  final double percentage;
  final Color color;

  const TransactionStatusBreakdown({
    required this.status,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

class LowStockAlertItem {
  final String name;
  final int stockQty;
  final String? imagePath;
  final String? imageUrl;
  final int id;

  const LowStockAlertItem({
    required this.name,
    required this.stockQty,
    this.imagePath,
    this.imageUrl,
    required this.id,
  });
}

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
    this.revenueGrowth,
    this.transactionsGrowth,
    this.productsCount = 0,
    this.topSelling = const [],
    this.paymentMethods = const [],
    this.transactionStatuses = const [],
    this.lowStockItems = const [],
    this.chartLabels = const [],
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
  final double? revenueGrowth;
  final double? transactionsGrowth;
  final int productsCount;
  final List<TopSellingItem> topSelling;
  final List<PaymentMethodBreakdown> paymentMethods;
  final List<TransactionStatusBreakdown> transactionStatuses;
  final List<LowStockAlertItem> lowStockItems;
  final List<String> chartLabels;

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
    productsCount: 0,
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
  late List<String> chartLabels;

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
    chartLabels = [
      DateFormat('E').format(today.subtract(const Duration(days: 2))),
      DateFormat('E').format(today.subtract(const Duration(days: 1))),
      'Today',
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
    chartLabels = [
      DateFormat('E').format(today.subtract(const Duration(days: 3))),
      DateFormat('E').format(today.subtract(const Duration(days: 2))),
      'Yesterday',
    ];
  } else if (period == DashboardPeriod.week) {
    start = weekStart(today);
    end = start.add(const Duration(days: 7));
    periodLabel = 'This Week';
    chartData = List.generate(7, (i) => _dayRevenue(sales, start.add(Duration(days: i))));
    chartLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  } else if (period == DashboardPeriod.month) {
    start = DateTime(now.year, now.month, 1);
    end = DateTime(now.year, now.month + 1, 1);
    periodLabel = 'This Month';
    final days = end.difference(start).inDays;
    chartData = List.generate(days, (i) => _dayRevenue(sales, start.add(Duration(days: i))));
    chartLabels = List.generate(days, (i) => '${i + 1}');
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
      chartLabels = [
        DateFormat('E').format(start.subtract(const Duration(days: 2))),
        DateFormat('E').format(start.subtract(const Duration(days: 1))),
        _fmtDate(start),
      ];
    } else {
      periodLabel =
          '${_fmtDate(customRange.start)} – ${_fmtDate(customRange.end)}';
      chartData = List.generate(days, (i) => _dayRevenue(sales, start.add(Duration(days: i))));
      chartLabels = List.generate(days, (i) => DateFormat('M/d').format(start.add(Duration(days: i))));
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
    chartLabels = [
      DateFormat('E').format(today.subtract(const Duration(days: 2))),
      DateFormat('E').format(today.subtract(const Duration(days: 1))),
      'Today',
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

  final lowStockCount = products.where((p) => !p.isService && p.effectiveStockQty <= criticalStockThreshold).length;

  // Compute growth rates comparing to previous period
  double prevRevenue = 0;
  int prevCount = 0;
  if (period == DashboardPeriod.today) {
    final yesterday = today.subtract(const Duration(days: 1));
    prevRevenue = _dayRevenue(sales, yesterday);
    prevCount = sales.where((s) => !s.createdAt.isBefore(yesterday) && s.createdAt.isBefore(today)).length;
  } else if (period == DashboardPeriod.yesterday) {
    final dayBefore = today.subtract(const Duration(days: 2));
    final yesterday = today.subtract(const Duration(days: 1));
    prevRevenue = _dayRevenue(sales, dayBefore);
    prevCount = sales.where((s) => !s.createdAt.isBefore(dayBefore) && s.createdAt.isBefore(yesterday)).length;
  } else if (period == DashboardPeriod.week) {
    final prevStart = start.subtract(const Duration(days: 7));
    prevRevenue = sales.where((s) => !s.createdAt.isBefore(prevStart) && s.createdAt.isBefore(start)).fold<double>(0, (sum, s) => sum + s.total);
    prevCount = sales.where((s) => !s.createdAt.isBefore(prevStart) && s.createdAt.isBefore(start)).length;
  }

  final double? revenueGrowth = prevRevenue > 0
      ? ((revenue - prevRevenue) / prevRevenue) * 100
      : (revenue > 0 ? 100.0 : null);

  final double? transactionsGrowth = prevCount > 0
      ? ((periodSales.length - prevCount) / prevCount.toDouble()) * 100
      : (periodSales.isNotEmpty ? 100.0 : null);

  // Top Selling Products aggregation
  final targetSales = periodSales.isNotEmpty ? periodSales : sales;
  final itemTotals = <String, ({int qty, double rev, int? prodId, String? prodUid})>{};
  for (final s in targetSales) {
    for (final it in s.items) {
      final key = it.name.trim();
      if (key.isEmpty) continue;
      final existing = itemTotals[key];
      if (existing == null) {
        itemTotals[key] = (
          qty: it.quantity,
          rev: it.lineTotal,
          prodId: it.productId,
          prodUid: it.productUid,
        );
      } else {
        itemTotals[key] = (
          qty: existing.qty + it.quantity,
          rev: existing.rev + it.lineTotal,
          prodId: existing.prodId ?? it.productId,
          prodUid: existing.prodUid ?? it.productUid,
        );
      }
    }
  }

  final sortedItems = itemTotals.entries.toList()
    ..sort((a, b) => b.value.qty.compareTo(a.value.qty));

  final topSelling = sortedItems.take(5).map((e) {
    final prod = products.where((p) {
      if (e.value.prodUid != null && p.uid == e.value.prodUid) return true;
      if (e.value.prodId != null && p.id == e.value.prodId) return true;
      return p.name.trim().toLowerCase() == e.key.toLowerCase();
    }).firstOrNull;

    return TopSellingItem(
      name: e.key,
      quantity: e.value.qty,
      totalRevenue: e.value.rev,
      imagePath: prod?.imagePath,
      imageUrl: prod?.imageUrl,
    );
  }).toList();

  // Payment Methods aggregation
  double cashRev = 0;
  double gcashRev = 0;
  double cardRev = 0;
  for (final s in targetSales) {
    final method = s.paymentMethod.toLowerCase();
    if (method.contains('gcash')) {
      gcashRev += s.total;
    } else if (method.contains('card') || method.contains('bank')) {
      cardRev += s.total;
    } else {
      cashRev += s.total;
    }
  }
  final totalPayRev = cashRev + gcashRev + cardRev;
  final paymentMethods = <PaymentMethodBreakdown>[
    PaymentMethodBreakdown(
      method: 'Cash',
      amount: cashRev,
      percentage: totalPayRev > 0 ? (cashRev / totalPayRev) * 100 : 0,
      color: const Color(0xFF3B82F6), // Blue
    ),
    PaymentMethodBreakdown(
      method: 'GCash',
      amount: gcashRev,
      percentage: totalPayRev > 0 ? (gcashRev / totalPayRev) * 100 : 0,
      color: const Color(0xFF10B981), // Green
    ),
    PaymentMethodBreakdown(
      method: 'Card',
      amount: cardRev,
      percentage: totalPayRev > 0 ? (cardRev / totalPayRev) * 100 : 0,
      color: const Color(0xFF8B5CF6), // Purple
    ),
  ];

  // Transaction Statuses aggregation
  int paidCount = 0;
  int cancelCount = 0;
  int refundCount = 0;
  for (final s in targetSales) {
    final st = s.status.toLowerCase();
    if (st == 'paid' || st == 'completed') {
      paidCount++;
    } else if (st == 'cancelled' || st == 'canceled') {
      cancelCount++;
    } else {
      refundCount++;
    }
  }
  final totalStatuses = paidCount + cancelCount + refundCount;
  final transactionStatuses = <TransactionStatusBreakdown>[
    TransactionStatusBreakdown(
      status: 'Completed',
      count: paidCount,
      percentage: totalStatuses > 0 ? (paidCount / totalStatuses) * 100 : 0,
      color: const Color(0xFF22C55E), // Green
    ),
    TransactionStatusBreakdown(
      status: 'Cancelled',
      count: cancelCount,
      percentage: totalStatuses > 0 ? (cancelCount / totalStatuses) * 100 : 0,
      color: const Color(0xFFEF4444), // Red
    ),
    TransactionStatusBreakdown(
      status: 'Refunded',
      count: refundCount,
      percentage: totalStatuses > 0 ? (refundCount / totalStatuses) * 100 : 0,
      color: const Color(0xFFF59E0B), // Amber
    ),
  ];

  // Low Stock Items list (critical red items <= 2)
  final lowStockProducts = products
      .where((p) => !p.isService && p.effectiveStockQty <= criticalStockThreshold)
      .toList()
    ..sort((a, b) => a.effectiveStockQty.compareTo(b.effectiveStockQty));

  final lowStockItems = lowStockProducts.take(5).map((p) => LowStockAlertItem(
    name: p.name,
    stockQty: p.effectiveStockQty,
    imagePath: p.imagePath,
    imageUrl: p.imageUrl,
    id: p.id,
  )).toList();

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
    revenueGrowth: revenueGrowth,
    transactionsGrowth: transactionsGrowth,
    productsCount: products.length,
    topSelling: topSelling,
    paymentMethods: paymentMethods,
    transactionStatuses: transactionStatuses,
    lowStockItems: lowStockItems,
    chartLabels: chartLabels,
  );
});
