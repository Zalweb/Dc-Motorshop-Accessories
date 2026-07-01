import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/sale.dart';

const salePaidColor = Color(0xFF22C55E);
const salePartialColor = Color(0xFFF59E0B);
const saleUnpaidColor = Color(0xFFEF4444);

/// Outstanding balance on a single sale. Fully-paid sales owe nothing.
/// Guards against non-finite legacy data (e.g. an unset amountReceived) by
/// falling back to the full total.
double saleBalance(Sale sale) {
  if (sale.status == 'paid') return 0;
  final received = sale.amountReceived.isFinite ? sale.amountReceived : 0;
  final raw = sale.total - received;
  if (!raw.isFinite) return sale.total.isFinite ? sale.total : 0;
  return raw < 0 ? 0 : raw;
}

(Color, String) saleStatusStyle(String status) => switch (status) {
      'paid' => (salePaidColor, 'PAID'),
      'partial' => (salePartialColor, 'PARTIAL'),
      _ => (saleUnpaidColor, 'UNPAID'),
    };

/// Colored pill showing a sale's payment status.
class SaleStatusChip extends StatelessWidget {
  const SaleStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = saleStatusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelCaps.copyWith(color: color, fontSize: 9),
      ),
    );
  }
}

/// Opens a sheet to record a payment against [sale]. Adding the amount lifts the
/// sale to 'paid' or 'partial'. Because a customer's balance is the sum of their
/// sale balances, settling a sale here automatically reduces the linked
/// customer's outstanding balance.
Future<void> showCompletePaymentSheet(
  BuildContext context,
  WidgetRef ref,
  Sale sale,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _CompletePaymentSheet(sale: sale, ref: ref),
  );

  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment recorded for ${sale.saleNumber}')),
    );
  }
}

class _CompletePaymentSheet extends StatefulWidget {
  const _CompletePaymentSheet({required this.sale, required this.ref});

  final Sale sale;
  final WidgetRef ref;

  @override
  State<_CompletePaymentSheet> createState() => _CompletePaymentSheetState();
}

class _CompletePaymentSheetState extends State<_CompletePaymentSheet> {
  late final TextEditingController _amount;
  bool _saving = false;

  double get _balance => saleBalance(widget.sale);

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: _balance.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _record() async {
    final entered = double.tryParse(_amount.text.trim()) ?? 0;
    if (entered <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount greater than zero')),
      );
      return;
    }

    setState(() => _saving = true);
    final sale = widget.sale;
    // Cap at the total — any extra is change, not an overpayment to store.
    final newReceived = (sale.amountReceived + entered).clamp(0, sale.total).toDouble();
    sale
      ..amountReceived = newReceived
      ..status = newReceived >= sale.total ? 'paid' : 'partial';
    await widget.ref.read(saleRepositoryProvider).save(sale);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sale = widget.sale;
    final customer = sale.customerName?.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Complete payment', style: AppTextStyles.headingMedium),
          const SizedBox(height: 4),
          Text(
            sale.saleNumber,
            style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          _SummaryRow(label: 'Total', value: formatPeso(sale.total)),
          const SizedBox(height: 6),
          _SummaryRow(label: 'Already received', value: formatPeso(sale.amountReceived)),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Balance due',
            value: formatPeso(_balance),
            color: saleUnpaidColor,
            bold: true,
          ),
          const SizedBox(height: 18),
          Text('Amount received now', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: const InputDecoration(prefixText: '₱ '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _QuickAmount(label: 'Full balance', onTap: () {
                _amount.text = _balance.toStringAsFixed(2);
                setState(() {});
              }),
              const SizedBox(width: 8),
              _QuickAmount(label: 'Half', onTap: () {
                _amount.text = (_balance / 2).toStringAsFixed(2);
                setState(() {});
              }),
            ],
          ),
          if (customer != null && customer.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Reduces $customer's outstanding balance.",
                    style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _record,
              style: FilledButton.styleFrom(
                backgroundColor: salePaidColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Record payment', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.color, this.bold = false});

  final String label;
  final String value;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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

class _QuickAmount extends StatelessWidget {
  const _QuickAmount({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(label, style: AppTextStyles.bodySmall),
    );
  }
}
