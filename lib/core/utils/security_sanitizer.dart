/// Core security utility providing sanitization and validation helpers
/// across both Mobile and Web platforms.
library;

/// Whitelist of safe, allowed image file extensions for uploads.
const Set<String> kAllowedImageExtensions = {'jpg', 'jpeg', 'png', 'webp'};

/// Maximum allowed length for a barcode, SKU, or search identifier.
const int kMaxBarcodeLength = 128;

/// Sanitizes user or scanner input intended for inclusion in PostgREST `.or(...)` filter strings.
///
/// PostgREST filter clauses use `(`, `)`, `,`, `"`, and `\` as structural delimiters.
/// This function strips those characters and control characters to prevent filter injection.
String sanitizePostgrestFilter(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';

  // Remove PostgREST control characters, parentheses, quotes, commas, and ASCII control codes.
  final sanitized = trimmed.replaceAll(RegExp(r'[\(\)",\\\x00-\x1F\x7F]'), '');
  if (sanitized.length > kMaxBarcodeLength) {
    return sanitized.substring(0, kMaxBarcodeLength);
  }
  return sanitized;
}

/// Sanitizes scanned barcodes or camera OCR outputs.
///
/// Strips null bytes, non-printable control characters, and truncates
/// excessively long payloads to prevent buffer overflows or UI issues.
String sanitizeBarcode(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  // Strip null bytes and non-printable control characters (except common printable characters).
  final sanitized = trimmed.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  if (sanitized.length > kMaxBarcodeLength) {
    return sanitized.substring(0, kMaxBarcodeLength);
  }
  return sanitized;
}

/// OWASP CWE-1236 mitigation: Neutralizes CSV/Excel formula injection characters
/// ('=', '+', '-', '@', '\t', '\r') by prefixing with a single quote to force text interpretation.
String sanitizeForSpreadsheet(String input) {
  if (input.isEmpty) return input;

  final first = input[0];
  if (first == '=' ||
      first == '+' ||
      first == '-' ||
      first == '@' ||
      first == '\t' ||
      first == '\r') {
    return "'$input";
  }

  final trimmed = input.trimLeft();
  if (trimmed.isNotEmpty) {
    final tFirst = trimmed[0];
    if (tFirst == '=' || tFirst == '+' || tFirst == '-' || tFirst == '@') {
      return "'$input";
    }
  }

  return input;
}

/// Validates that a file extension is in the allowed whitelist of safe image formats.
bool isAllowedImageExtension(String ext) {
  final clean = ext.replaceAll('.', '').trim().toLowerCase();
  return kAllowedImageExtensions.contains(clean);
}

/// Validates a path/identifier to prevent path traversal attempts (e.g. '../' or '..\\').
bool isSafeIdentifier(String identifier) {
  if (identifier.isEmpty) return false;
  if (identifier.contains('..') ||
      identifier.contains('/') ||
      identifier.contains(r'\') ||
      identifier.contains('\x00')) {
    return false;
  }
  return RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(identifier);
}
