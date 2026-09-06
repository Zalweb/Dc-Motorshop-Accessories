import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/sale.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/tactile_button.dart';
import 'receipt_print.dart';

/// Professional POS confirmation dialog displaying the sale summary,
/// change calculator, authentic thermal receipt breakdown, and printing tools.
class SaleCompleteDialog extends ConsumerWidget {
  const SaleCompleteDialog({super.key, required this.sale});

  final Sale sale;
  static const _success = Color(0xFF10B981);

  double get changeDue {
    final paid = sale.amountReceived;
    return paid > sale.total ? paid - sale.total : 0.0;
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy  •  h:mm a').format(dt);
  }

  String _generatePlainTextReceipt({
    String businessName = 'DC Motorshop and Accessories',
    String? qrLink,
  }) {
    final sb = StringBuffer();
    sb.writeln('================================');
    sb.writeln('  ${businessName.toUpperCase()}  ');
    sb.writeln('  Motorcycle Parts & Services ');
    sb.writeln('================================');
    sb.writeln('Invoice: #${sale.saleNumber}');
    sb.writeln('Date: ${_formatDateTime(sale.createdAt)}');
    if (sale.customerName != null && sale.customerName!.trim().isNotEmpty) {
      sb.writeln('Customer: ${sale.customerName!.trim()}');
    }
    sb.writeln('Method: ${sale.paymentMethod.toUpperCase()}');
    sb.writeln('--------------------------------');
    sb.writeln('ITEM                        TOTAL');
    sb.writeln('--------------------------------');
    for (final item in sale.items) {
      final name = item.variantName != null && item.variantName!.isNotEmpty
          ? '${item.name} (${item.variantName})'
          : item.name;
      sb.writeln('${item.quantity}x $name');
      final priceLine =
          '   @ ${formatPeso(item.unitPrice)}        ${formatPeso(item.lineTotal)}';
      sb.writeln(priceLine);
    }
    sb.writeln('--------------------------------');
    sb.writeln('SUBTOTAL:         ${formatPeso(sale.subtotal)}');
    if (sale.discount > 0) {
      sb.writeln('DISCOUNT:        -${formatPeso(sale.discount)}');
    }
    sb.writeln('TOTAL:            ${formatPeso(sale.total)}');
    sb.writeln('TENDERED:         ${formatPeso(sale.amountReceived)}');
    sb.writeln('CHANGE DUE:       ${formatPeso(changeDue)}');
    sb.writeln('================================');
    sb.writeln('   THANK YOU FOR YOUR PATRONAGE!  ');
    sb.writeln('   Please keep for warranty.    ');
    if (qrLink != null && qrLink.trim().isNotEmpty) {
      sb.writeln('   ${qrLink.trim()}   ');
    }
    sb.writeln('================================');
    return sb.toString();
  }

  String _generateHtmlReceipt({
    String businessName = 'DC Motorshop and Accessories',
    String? qrLink,
    String? logoPath,
  }) {
    final itemsRows = sale.items.map((item) {
      final name = item.variantName != null && item.variantName!.isNotEmpty
          ? '${item.name} (${item.variantName})'
          : item.name;
      return '''
        <tr>
          <td style="padding: 4px 0;"><strong>${item.quantity}x</strong> $name</td>
          <td style="text-align: right; padding: 4px 0;">${formatPeso(item.lineTotal)}</td>
        </tr>
      ''';
    }).join();

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <title>Receipt #${sale.saleNumber}</title>
        <style>
          body {
            font-family: 'Courier New', Courier, monospace;
            width: 300px;
            margin: 0 auto;
            padding: 16px;
            color: #000;
          }
          .center { text-align: center; }
          .bold { font-weight: bold; }
          .divider { border-top: 1px dashed #000; margin: 8px 0; }
          .double-divider { border-top: 2px solid #000; margin: 10px 0; }
          table { width: 100%; border-collapse: collapse; font-size: 13px; }
          .footer { font-size: 11px; margin-top: 16px; text-align: center; }
        </style>
      </head>
      <body>
        ${(logoPath != null && logoPath.isNotEmpty) ? '<div class="center" style="margin-bottom: 8px;"><img src="$logoPath" style="max-height: 48px; max-width: 140px; object-fit: contain;" /></div>' : ''}
        <div class="center bold" style="font-size: 16px;">${businessName.toUpperCase()}</div>
        <div class="center" style="font-size: 12px; margin-bottom: 8px;">Motorcycle Parts & Expert Services</div>
        <div class="divider"></div>
        <div style="font-size: 12px;">
          <div><strong>Receipt #:</strong> ${sale.saleNumber}</div>
          <div><strong>Date:</strong> ${_formatDateTime(sale.createdAt)}</div>
          ${sale.customerName != null && sale.customerName!.trim().isNotEmpty ? '<div><strong>Customer:</strong> ${sale.customerName!.trim()}</div>' : ''}
          <div><strong>Payment:</strong> ${sale.paymentMethod.toUpperCase()}</div>
        </div>
        <div class="divider"></div>
        <table>$itemsRows</table>
        <div class="divider"></div>
        <table>
          <tr><td>Subtotal:</td><td style="text-align:right;">${formatPeso(sale.subtotal)}</td></tr>
          ${sale.discount > 0 ? '<tr><td>Discount:</td><td style="text-align:right;">-${formatPeso(sale.discount)}</td></tr>' : ''}
          <tr style="font-weight: bold; font-size: 15px;">
            <td style="padding-top: 4px;">TOTAL:</td>
            <td style="text-align:right; padding-top: 4px;">${formatPeso(sale.total)}</td>
          </tr>
          <tr><td>Paid:</td><td style="text-align:right;">${formatPeso(sale.amountReceived)}</td></tr>
          <tr style="font-weight: bold; font-size: 14px;">
            <td>CHANGE:</td>
            <td style="text-align:right;">${formatPeso(changeDue)}</td>
          </tr>
        </table>
        <div class="double-divider"></div>
        <div class="footer">
          THANK YOU FOR YOUR PATRONAGE!<br>
          Please keep this receipt for reference.
          ${(qrLink != null && qrLink.trim().isNotEmpty) ? '<div class="center" style="margin-top: 10px;"><img src="https://api.qrserver.com/v1/create-qr-code/?size=100x100&data=${Uri.encodeComponent(qrLink.trim())}" style="width: 90px; height: 90px;" alt="QR Code" /><br><span style="word-break: break-all; font-size: 10px;">${qrLink.trim()}</span></div>' : ''}
        </div>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final settings = ref.watch(businessSettingsStreamProvider).value;
    final businessName = (settings?.businessName != null && settings!.businessName.trim().isNotEmpty)
        ? settings.businessName.trim()
        : 'DC Motorshop and Accessories';
    final qrLink = settings?.receiptQrLink?.trim();
    final logoPath = settings?.logoPath?.trim();

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          children: [
            // Header with Success Checkmark
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _success.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: _success,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sale Completed!',
                    style: AppTextStyles.headingMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Receipt #${sale.saleNumber}  •  ${_formatDateTime(sale.createdAt)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Quick Change & Payment Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL DUE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatPeso(sale.total),
                          style: AppTextStyles.headingMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tendered: ${formatPeso(sale.amountReceived)} (${sale.paymentMethod.toUpperCase()})',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _success.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _success.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'CHANGE DUE',
                            style: TextStyle(
                              color: _success,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatPeso(changeDue),
                            style: const TextStyle(
                              color: _success,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Scrollable Authentic Thermal Receipt Box
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF14171E) : const Color(0xFFF9F9F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF222222),
                        height: 1.4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (logoPath != null && logoPath.isNotEmpty) ...[
                            Center(
                              child: AppImage(
                                imageUrl: logoPath,
                                imagePath: logoPath,
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Center(
                            child: Text(
                              businessName.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Center(
                            child: Text(
                              'Motorcycle Parts & Expert Services',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('----------------------------------------',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          if (sale.customerName != null &&
                              sale.customerName!.trim().isNotEmpty) ...[
                            Text('Customer: ${sale.customerName!.trim()}'),
                            const SizedBox(height: 2),
                          ],
                          for (final item in sale.items) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantity}x ${item.variantName != null && item.variantName!.isNotEmpty ? "${item.name} (${item.variantName})" : item.name}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(formatPeso(item.lineTotal)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          const Text('----------------------------------------',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text(formatPeso(sale.subtotal)),
                            ],
                          ),
                          if (sale.discount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Discount:'),
                                Text('-${formatPeso(sale.discount)}'),
                              ],
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL:',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(formatPeso(sale.total),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Paid:'),
                              Text(formatPeso(sale.amountReceived)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Change:',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(formatPeso(changeDue),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Center(
                            child: Text(
                              '*** THANK YOU FOR VISITING! ***',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (qrLink != null && qrLink.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                qrLink,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Footer Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TactileButton(
                      scaleDown: 0.95,
                      hoverScale: 1.02,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final text = _generatePlainTextReceipt(
                            businessName: businessName,
                            qrLink: qrLink,
                          );
                          final html = _generateHtmlReceipt(
                            businessName: businessName,
                            qrLink: qrLink,
                            logoPath: logoPath,
                          );
                          await printOrShareReceipt(
                            receiptText: text,
                            htmlContent: html,
                            title: 'Receipt #${sale.saleNumber}',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Receipt ready / printed'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text('Print Receipt'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TactileButton(
                      scaleDown: 0.95,
                      hoverScale: 1.02,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('New Sale'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to trigger the dialog directly.
Future<void> showSaleCompleteDialog(BuildContext context, Sale sale) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => SaleCompleteDialog(sale: sale),
  );
}
