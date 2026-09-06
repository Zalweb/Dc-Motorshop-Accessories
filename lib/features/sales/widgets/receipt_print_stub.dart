import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

Future<void> printOrShareReceipt({
  required String receiptText,
  required String htmlContent,
  required String title,
}) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: receiptText,
        subject: title,
      ),
    );
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: receiptText));
  }
}
