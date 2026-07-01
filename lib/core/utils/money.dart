import 'package:intl/intl.dart';

final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

/// Formats an amount as Philippine Pesos, e.g. 1234.5 → "₱1,234.50".
String formatPeso(num amount) => _peso.format(amount);
