import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/sale.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/search_field.dart';
import '../sales/sale_payment.dart';

/// One customer rolled up from every sale that carried their name.
class CustomerSummary {
  CustomerSummary(this.name, this.sales);

  final String name;
  final List<Sale> sales;

  int get orderCount => sales.length;
  double get totalSpent => sales.fold(0, (sum, s) => sum + s.total);
  double get outstanding => sales.fold(0, (sum, s) => sum + saleBalance(s));
  DateTime get lastVisit => sales.map((s) => s.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }
}

/// Groups sales by customer name (case-insensitive), newest-spend first when
/// money is owed, otherwise most recent visit.
List<CustomerSummary> buildCustomerSummaries(List<Sale> sales) {
  final byKey = <String, List<Sale>>{};
  final displayName = <String, String>{};
  for (final sale in sales) {
    final name = sale.customerName?.trim();
    if (name == null || name.isEmpty) continue;
    final key = name.toLowerCase();
    byKey.putIfAbsent(key, () => []).add(sale);
    displayName.putIfAbsent(key, () => name);
  }

  final summaries = byKey.entries.map((e) => CustomerSummary(displayName[e.key]!, e.value)).toList();
  summaries.sort((a, b) {
    if ((a.outstanding > 0) != (b.outstanding > 0)) return a.outstanding > 0 ? -1 : 1;
    if (a.outstanding != b.outstanding) return b.outstanding.compareTo(a.outstanding);
    return b.lastVisit.compareTo(a.lastVisit);
  });
  return summaries;
}

/// Customer ledger reachable from More → Finance. Lists every customer captured
/// on a sale, surfacing any unpaid balances.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(saleListStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchField(
              hint: 'Search customers...',
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: salesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (sales) {
                final all = buildCustomerSummaries(sales);
                final filtered = _query.isEmpty
                    ? all
                    : all.where((c) => c.name.toLowerCase().contains(_query)).toList();

                if (all.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_alt_outlined,
                    title: 'No customers yet',
                    body: 'Add a customer name when creating a sale and they\'ll appear here.',
                  );
                }
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No matches',
                    body: 'No customer matches your search.',
                  );
                }

                final totalOwed = all.fold<double>(0, (sum, c) => sum + c.outstanding);
                final debtors = all.where((c) => c.outstanding > 0).length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    if (totalOwed > 0) ...[
                      _ReceivablesBanner(totalOwed: totalOwed, debtors: debtors),
                      const SizedBox(height: 16),
                    ],
                    for (final customer in filtered) ...[
                      _CustomerTile(customer: customer),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivablesBanner extends StatelessWidget {
  const _ReceivablesBanner({required this.totalOwed, required this.debtors});

  final double totalOwed;
  final int debtors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: saleUnpaidColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: saleUnpaidColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: saleUnpaidColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL RECEIVABLES',
                    style: AppTextStyles.labelCaps.copyWith(color: saleUnpaidColor)),
                const SizedBox(height: 4),
                Text(
                  formatPeso(totalOwed),
                  style: AppTextStyles.headingMedium.copyWith(color: saleUnpaidColor, fontSize: 22),
                ),
              ],
            ),
          ),
          Text(
            '$debtors ${debtors == 1 ? 'customer' : 'customers'}\nowe you',
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(color: saleUnpaidColor),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});

  final CustomerSummary customer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final owes = customer.outstanding > 0;
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          child: Text(
            customer.initials.isEmpty ? '?' : customer.initials,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        title: Text(customer.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${customer.orderCount} order(s) · ${formatPeso(customer.totalSpent)} spent',
          style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: owes
              ? [
                  Text('BALANCE',
                      style: AppTextStyles.labelCaps.copyWith(color: saleUnpaidColor, fontSize: 9)),
                  const SizedBox(height: 2),
                  Text(formatPeso(customer.outstanding),
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w800, color: saleUnpaidColor)),
                ]
              : [
                  Icon(Icons.check_circle_outline, color: salePaidColor, size: 18),
                  const SizedBox(height: 2),
                  Text('Paid up',
                      style: AppTextStyles.bodySmall.copyWith(color: salePaidColor)),
                ],
        ),
        onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerName: customer.name)),
        ),
      ),
    );
  }
}

/// Per-customer history with each sale's payment status and balance, plus a
/// shortcut to settle outstanding sales.
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerName});

  final String customerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(saleListStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(customerName), centerTitle: true),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (sales) {
          final key = customerName.trim().toLowerCase();
          final mine = sales.where((s) => (s.customerName?.trim().toLowerCase() ?? '') == key).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (mine.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No sales',
              body: 'This customer has no recorded sales.',
            );
          }

          final summary = CustomerSummary(customerName, mine);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              _DetailHeader(summary: summary),
              const SizedBox(height: 20),
              Text('SALES', style: AppTextStyles.labelCaps.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              for (final sale in mine) ...[
                _SaleRow(
                  sale: sale,
                  onMarkPaid: () => showCompletePaymentSheet(context, ref, sale),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.summary});

  final CustomerSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final owes = summary.outstanding > 0;
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  summary.initials.isEmpty ? '?' : summary.initials,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontSize: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.name, style: AppTextStyles.headingMedium.copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(
                      'Last visit ${DateFormat('MMM d, yyyy').format(summary.lastVisit)}',
                      style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(label: 'ORDERS', value: '${summary.orderCount}'),
              _Stat(label: 'SPENT', value: formatPeso(summary.totalSpent)),
              _Stat(
                label: 'BALANCE',
                value: formatPeso(summary.outstanding),
                color: owes ? saleUnpaidColor : salePaidColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelCaps.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 9)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w800,
              color: color ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.sale, required this.onMarkPaid});

  final Sale sale;
  final VoidCallback onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = saleBalance(sale);
    final itemCount = sale.items.fold<int>(0, (sum, it) => sum + it.quantity);

    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sale.saleNumber, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '$itemCount item(s) · ${DateFormat('MMM d, yyyy · h:mm a').format(sale.createdAt)}',
                      style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatPeso(sale.total), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  SaleStatusChip(status: sale.status),
                ],
              ),
            ],
          ),
          if (balance > 0) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.error_outline, color: saleUnpaidColor, size: 18),
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
                // Custom pill (not a Material button) so the Row's unbounded
                // measure pass can't force it to infinite width and abort layout.
                GestureDetector(
                  onTap: onMarkPaid,
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
    );
  }
}
