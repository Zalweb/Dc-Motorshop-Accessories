// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/services.dart';

Future<void> printOrShareReceipt({
  required String receiptText,
  required String htmlContent,
  required String title,
}) async {
  try {
    // Inject auto-print script into HTML
    final printableHtml = '''
$htmlContent
<script>
  window.onload = function() {
    window.print();
  };
</script>
''';
    final blob = html.Blob([printableHtml], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    return;
  } catch (_) {
    try {
      html.window.print();
      return;
    } catch (_) {}
  }

  await Clipboard.setData(ClipboardData(text: receiptText));
}
