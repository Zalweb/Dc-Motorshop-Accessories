import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/sale.dart';
import '../../shared/widgets/glass_container.dart';
import 'sale_payment.dart';

/// Full breakdown of one sale: line items, totals, payment status, and a
/// complete-payment action when a balance is outstanding.
class SaleDetailScreen extends ConsumerWidget {
  const SaleDetailScreen({super.key, required this.saleUid});

  final String saleUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sales = ref.watch(saleListStreamProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Sale details'), centerTitle: true),
      body: Builder(
        builder: (_) {
          if (sales == null) {
            return const Center(child: CircularProgressIndicator());
          }
          Sale? sale;
          for (final s in sales) {
            if (s.uid == saleUid) {
              sale = s;
              break;
            }
          }
          if (sale == null) {
            return const Center(child: Text('Sale not found.'));
          }

          final balance = saleBalance(sale);
          final itemCount = sale.items.fold<int>(0, (sum, it) => sum + it.quantity);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(sale.saleNumber, style: AppTextStyles.headingMedium.copyWith(fontSize: 18)),
                        ),
                        SaleStatusChip(status: sale.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM d, yyyy · h:mm a').format(sale.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    _MetaRow(icon: Icons.person_outline, value: sale.customerName ?? 'Walk-in'),
                    const SizedBox(height: 8),
                    _MetaRow(
                      icon: Icons.payments_outlined,
                      value: '${_methodLabel(sale.paymentMethod)} · $itemCount item(s)',
                    ),
                    if (sale.notes != null && sale.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _MetaRow(icon: Icons.sticky_note_2_outlined, value: sale.notes!.trim()),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text('ITEMS', style: AppTextStyles.labelCaps.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    for (var i = 0; i < sale.items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _ItemRow(item: sale.items[i]),
                    ],
                    const SizedBox(height: 14),
                    Divider(height: 1, color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 14),
                    _TotalRow(label: 'Subtotal', value: formatPeso(sale.subtotal)),
                    if (sale.discount > 0) ...[
                      const SizedBox(height: 6),
                      _TotalRow(label: 'Discount', value: '−${formatPeso(sale.discount)}'),
                    ],
                    const SizedBox(height: 6),
                    _TotalRow(label: 'Total', value: formatPeso(sale.total), bold: true),
                    const SizedBox(height: 6),
                    _TotalRow(label: 'Amount received', value: formatPeso(sale.amountReceived)),
                    if (balance > 0) ...[
                      const SizedBox(height: 6),
                      _TotalRow(label: 'Balance due', value: formatPeso(balance), color: saleUnpaidColor, bold: true),
                    ],
                  ],
                ),
              ),

              if (balance > 0) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => showCompletePaymentSheet(context, ref, sale!),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text('Complete payment · ${formatPeso(balance)}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: salePaidColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _methodLabel(String method) => switch (method) {
        'gcash' => 'GCash',
        'bank' => 'Bank transfer',
        'card' => 'Card',
        _ => 'Cash',
      };
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurface))),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final SaleItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                '${item.quantity} × ${formatPeso(item.unitPrice)}',
                style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Text(formatPeso(item.lineTotal), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.bold = false, this.color});

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: color ?? theme.colorScheme.onSurfaceVariant,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
