import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';

const _headers = ['Qty', 'Name', 'Brand', 'Part Number', 'Price', 'Status', 'Date'];

enum _ExportAction { save, share }

/// Asks how to export [sales] (already filtered by the caller) — save to the
/// device or share — then builds an .xlsx (one row per line item) and runs it.
Future<void> exportSalesToExcel(
  BuildContext context,
  WidgetRef ref,
  List<Sale> sales,
) async {
  final messenger = ScaffoldMessenger.of(context);

  if (sales.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('No sales to export.')));
    return;
  }

  final action = await showModalBottomSheet<_ExportAction>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Export sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          ListTile(
            leading: Icon(Icons.download_rounded, color: Theme.of(ctx).colorScheme.primary),
            title: const Text('Save to device'),
            subtitle: const Text('Download the Excel file to your phone'),
            onTap: () => Navigator.pop(ctx, _ExportAction.save),
          ),
          ListTile(
            leading: Icon(Icons.ios_share_rounded, color: Theme.of(ctx).colorScheme.primary),
            title: const Text('Share'),
            subtitle: const Text('Send via another app (email, chat, Drive…)'),
            onTap: () => Navigator.pop(ctx, _ExportAction.share),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );

  if (action == null) return;

  try {
    final built = await _buildWorkbook(ref, sales);
    if (built == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not build the Excel file.')));
      return;
    }

    switch (action) {
      case _ExportAction.save:
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save sales export',
          fileName: built.fileName,
          type: FileType.custom,
          allowedExtensions: const ['xlsx'],
          bytes: built.bytes,
        );
        messenger.showSnackBar(SnackBar(
          content: Text(path == null ? 'Save cancelled.' : 'Saved to device.'),
        ));
      case _ExportAction.share:
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${built.fileName}');
        await file.writeAsBytes(built.bytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile(
                file.path,
                mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              ),
            ],
            subject: 'Sales export',
          ),
        );
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}

class _Workbook {
  _Workbook(this.bytes, this.fileName);
  final Uint8List bytes;
  final String fileName;
}

/// Builds the .xlsx bytes — one row per line item. Brand and part number are
/// looked up from the product catalog since a sale line only snapshots name,
/// quantity, and price.
Future<_Workbook?> _buildWorkbook(WidgetRef ref, List<Sale> sales) async {
  final products = await ref.read(productRepositoryProvider).all();
  final byUid = <String, Product>{};
  final byId = <int, Product>{};
  final byName = <String, Product>{};
  for (final p in products) {
    byUid[p.uid] = p;
    byId[p.id] = p;
    byName[p.name.toLowerCase()] = p;
  }

  final excel = xls.Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
  excel.rename(defaultSheet, 'Sales');
  final sheet = excel['Sales'];

  sheet.appendRow([for (final h in _headers) xls.TextCellValue(h)]);

  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  for (final sale in sales) {
    for (final item in sale.items) {
      final product = byUid[item.productUid] ??
          (item.productId != null ? byId[item.productId] : null) ??
          byName[item.name.toLowerCase()];
      sheet.appendRow([
        xls.IntCellValue(item.quantity),
        xls.TextCellValue(item.name),
        xls.TextCellValue(product?.brand ?? ''),
        xls.TextCellValue(product?.partNumber ?? ''),
        xls.DoubleCellValue(item.unitPrice),
        xls.TextCellValue(_statusLabel(sale.status)),
        xls.TextCellValue(dateFormat.format(sale.createdAt)),
      ]);
    }
  }

  final bytes = excel.save();
  if (bytes == null) return null;

  final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  return _Workbook(Uint8List.fromList(bytes), 'sales_export_$stamp.xlsx');
}

String _statusLabel(String status) => switch (status) {
      'paid' => 'Paid',
      'partial' => 'Partial',
      _ => 'Unpaid',
    };
