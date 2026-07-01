import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/sale.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/search_field.dart';
import 'sale_detail_screen.dart';
import 'sale_payment.dart';
import 'sales_export.dart';

/// Preset windows for the date filter, plus a custom range.
enum DateFilter { all, today, yesterday, last7, thisMonth, custom }

extension on DateFilter {
  String get label => switch (this) {
        DateFilter.all => 'All time',
        DateFilter.today => 'Today',
        DateFilter.yesterday => 'Yesterday',
        DateFilter.last7 => 'Last 7 days',
        DateFilter.thisMonth => 'This month',
        DateFilter.custom => 'Custom range',
      };
}

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  String _query = '';
  DateFilter _filter = DateFilter.all;
  DateTimeRange? _customRange;

  /// Inclusive [start, end] for the active filter, or null for all time.
  (DateTime, DateTime)? get _range {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (_filter) {
      case DateFilter.all:
        return null;
      case DateFilter.today:
        return (startOfToday, startOfToday.add(const Duration(days: 1)));
      case DateFilter.yesterday:
        return (startOfToday.subtract(const Duration(days: 1)), startOfToday);
      case DateFilter.last7:
        return (startOfToday.subtract(const Duration(days: 6)), startOfToday.add(const Duration(days: 1)));
      case DateFilter.thisMonth:
        return (DateTime(now.year, now.month), DateTime(now.year, now.month + 1));
      case DateFilter.custom:
        if (_customRange == null) return null;
        return (
          _customRange!.start,
          DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day)
              .add(const Duration(days: 1)),
        );
    }
  }

  List<Sale> _apply(List<Sale> sales) {
    var result = sales;
    final range = _range;
    if (range != null) {
      result = result
          .where((s) => !s.createdAt.isBefore(range.$1) && s.createdAt.isBefore(range.$2))
          .toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      result = result
          .where((s) =>
              s.saleNumber.toLowerCase().contains(q) ||
              (s.customerName?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return result;
  }

  Future<void> _pickFilter() async {
    final selected = await showModalBottomSheet<DateFilter>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Filter by date', style: AppTextStyles.headingMedium),
              ),
            ),
            for (final option in DateFilter.values)
              ListTile(
                leading: Icon(
                  _filter == option ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _filter == option
                      ? Theme.of(ctx).colorScheme.primary
                      : Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
                title: Text(option.label, style: AppTextStyles.body),
                onTap: () => Navigator.pop(ctx, option),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;

    if (selected == DateFilter.custom) {
      final now = DateTime.now();
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 5),
        lastDate: now,
        initialDateRange: _customRange,
      );
      if (range == null) return;
      setState(() {
        _filter = DateFilter.custom;
        _customRange = range;
      });
    } else {
      setState(() => _filter = selected);
    }
  }

  String get _filterLabel {
    if (_filter == DateFilter.custom && _customRange != null) {
      final f = DateFormat('MMM d');
      return '${f.format(_customRange!.start)} – ${f.format(_customRange!.end)}';
    }
    return _filter.label;
  }

  @override
  Widget build(BuildContext context) {
    // Read like the dashboard/reports do (.value) so a transient loading/error
    // tick on the stream can't hide sales that are already present.
    final sales = ref.watch(saleListStreamProvider).value;
    final theme = Theme.of(context);
    final filterActive = _filter != DateFilter.all;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            tooltip: 'Export to Excel',
            onPressed: sales == null
                ? null
                : () => exportSalesToExcel(context, ref, _apply(sales)),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            tooltip: 'Filter by date',
            onPressed: _pickFilter,
            icon: Badge(
              isLabelVisible: filterActive,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchField(
              hint: 'Search by sale number or customer...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (filterActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.primary),
                  label: Text(_filterLabel),
                  onDeleted: () => setState(() {
                    _filter = DateFilter.all;
                    _customRange = null;
                  }),
                ),
              ),
            ),
          Expanded(
            child: Builder(
              builder: (_) {
                if (sales == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final filtered = _apply(sales);
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: filterActive || _query.isNotEmpty ? 'No matching sales' : 'No sales yet',
                    body: filterActive || _query.isNotEmpty
                        ? 'Try a different date range or search.'
                        : 'New sales will show up here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _SaleTile(sale: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleTile extends ConsumerWidget {
  const _SaleTile({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final itemCount = sale.items.fold<int>(0, (sum, it) => sum + it.quantity);
    final balance = saleBalance(sale);
    final (statusColor, _) = saleStatusStyle(sale.status);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => SaleDetailScreen(saleUid: sale.uid)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status color bar indicator.
                  Container(
                    width: 4,
                    height: 36,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(sale.saleNumber,
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            SaleStatusChip(status: sale.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sale.customerName ?? 'Walk-in'} · $itemCount item(s) · '
                          '${DateFormat('MMM d, h:mm a').format(sale.createdAt)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(formatPeso(sale.total),
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              if (balance > 0) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.error_outline, color: saleUnpaidColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Balance due ${formatPeso(balance)}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: saleUnpaidColor,
                        ),
                      ),
                    ),
                    // Custom pill (not a Material button) so it shrink-wraps and
                    // can't be forced to infinite width during the Row's measure
                    // pass, which would abort the whole list's layout.
                    GestureDetector(
                      onTap: () => showCompletePaymentSheet(context, ref, sale),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: salePaidColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Complete payment',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }
}
