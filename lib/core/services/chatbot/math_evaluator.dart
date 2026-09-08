import 'package:intl/intl.dart';

import 'chatbot_models.dart';

class MathEvaluator {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  static final NumberFormat _decimalFormat = NumberFormat('#,##0.##', 'en_US');

  /// Tries to evaluate a query as a math, percentage, discount, change, margin, or parts+labor problem.
  /// Returns null if query does not match any calculator pattern.
  static CalculatorResult? tryEvaluate(String query) {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return null;

    // 1. Markup Pattern (e.g. "markup 30% on 500")
    final markupResult = _evalMarkup(text);
    if (markupResult != null) return markupResult;

    // 2. Discount Pattern (e.g. "10% off on 1500", "1500 less 10%", "10 percent discount")
    final discountResult = _evalDiscount(text);
    if (discountResult != null) return discountResult;

    // 3. Percentage Calculation (e.g. "10% of 1500", "what is 12% of 3500")
    final percentageResult = _evalPercentage(text);
    if (percentageResult != null) return percentageResult;

    // 4. Change / Sukli Pattern
    final changeResult = _evalChange(text);
    if (changeResult != null) return changeResult;

    // 5. Profit / Margin Pattern (e.g. "cost 200 sell 350", "puhunan 200 srp 350")
    final profitResult = _evalProfitMargin(text);
    if (profitResult != null) return profitResult;

    // 6. Parts + Labor Pattern (e.g. "parts 850 labor 300", "parts: 500, labor: 200")
    final partsLaborResult = _evalPartsLabor(text);
    if (partsLaborResult != null) return partsLaborResult;

    // 7. Direct Math Expression Pattern (e.g. "500 - 320", "500 minus 320", "4 x 280", "4 times 280", "total 250 + 180 + 90")
    final mathResult = _evalMathExpression(text);
    if (mathResult != null) return mathResult;

    return null;
  }

  // ── 1. Percentage Evaluator ────────────────────────────────────────────
  static CalculatorResult? _evalPercentage(String rawText) {
    var text = rawText
        .replaceAll('percent', '%')
        .replaceAll('porsyento', '%');

    // "10% of 1500", "what is 12% of 2500", "10% ng 1500", "12% vat on 2500"
    final pattern = RegExp(
      r'(?:what\s+is\s+|how\s+much\s+is\s+|magkano\s+ang\s+)?(?:(\d+(?:\.\d+)?)\s*%\s*(?:vat|tax)?\s*(?:of|on|from|sa|ng)\s*(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?))',
    );
    final match = pattern.firstMatch(text);
    if (match != null) {
      final rate = double.tryParse(match.group(1)!) ?? 0;
      final base = double.tryParse(match.group(2)!.replaceAll(',', '')) ?? 0;
      final amount = base * (rate / 100);

      return CalculatorResult(
        success: true,
        expression: '$rate% of ${_currencyFormat.format(base)}',
        value: amount,
        formattedValue: _currencyFormat.format(amount),
        breakdown:
            '$rate% of ${_currencyFormat.format(base)} = ${_currencyFormat.format(amount)}',
        category: CalculatorCategory.math,
      );
    }
    return null;
  }

  // ── 2. Discount Evaluator ──────────────────────────────────────────────
  static CalculatorResult? _evalDiscount(String rawText) {
    var text = rawText
        .replaceAll('percent', '%')
        .replaceAll('porsyento', '%');

    // "10% off 1500", "10% off on 1500", "10% discount on 1500", "bawas 10% sa 1500"
    final pattern1 = RegExp(
      r'(?:(\d+(?:\.\d+)?)\s*%\s*(?:off|discount|bawas)\s*(?:on|from|sa|of)?\s*(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?))',
    );
    final match1 = pattern1.firstMatch(text);
    if (match1 != null) {
      final rate = double.tryParse(match1.group(1)!) ?? 0;
      final base = double.tryParse(match1.group(2)!.replaceAll(',', '')) ?? 0;
      return _buildDiscountResult(base, rate);
    }

    // "discount of 10% on 1500", "discount 20% on 850"
    final pattern2 = RegExp(
      r'(?:(?:discount|bawas)\s*(?:of|na)?\s*(\d+(?:\.\d+)?)\s*%\s*(?:on|from|sa|of|for)?\s*(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?))',
    );
    final match2 = pattern2.firstMatch(text);
    if (match2 != null) {
      final rate = double.tryParse(match2.group(1)!) ?? 0;
      final base = double.tryParse(match2.group(2)!.replaceAll(',', '')) ?? 0;
      return _buildDiscountResult(base, rate);
    }

    // "1500 less 10%", "1500 - 10%", "1500 minus 10%", "1500 with 10% discount"
    final pattern3 = RegExp(
      r'(?:(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?)\s*(?:less|minus|-|with)\s*(\d+(?:\.\d+)?)\s*%(?:\s*(?:off|discount))?)',
    );
    final match3 = pattern3.firstMatch(text);
    if (match3 != null) {
      final base = double.tryParse(match3.group(1)!.replaceAll(',', '')) ?? 0;
      final rate = double.tryParse(match3.group(2)!) ?? 0;
      return _buildDiscountResult(base, rate);
    }

    return null;
  }

  static CalculatorResult _buildDiscountResult(double base, double rate) {
    final discountAmount = base * (rate / 100);
    final finalPrice = base - discountAmount;
    final breakdown =
        'Original: ${_currencyFormat.format(base)} | Less $rate% (-${_currencyFormat.format(discountAmount)})';
    return CalculatorResult(
      success: true,
      expression: '${_currencyFormat.format(base)} less $rate%',
      value: finalPrice,
      formattedValue: _currencyFormat.format(finalPrice),
      breakdown: breakdown,
      category: CalculatorCategory.discount,
    );
  }

  // ── 3. Sukli / Change Evaluator ─────────────────────────────────────────
  static CalculatorResult? _evalChange(String text) {
    if (!text.contains('sukli') &&
        !text.contains('change') &&
        !text.contains('inabot') &&
        !text.contains('tendered') &&
        !text.contains('suklian')) {
      return null;
    }

    // Explicit cash & bill order pattern:
    // e.g. "tendered 500 bill 650", "bayad 1000 bill 750", "sukli sa 500 bill 650"
    final cashThenBill = RegExp(
      r'(?:cash|tendered|bayad|inabot|sa|ng)\s*(?:ay|is|ng|na)?\s*(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?).*(?:bill|total|order|benta|halaga|kung)\s*(?:ay|is|ng|na)?\s*(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?)',
    );
    final billThenCash = RegExp(
      r'(?:bill|total|order|benta|halaga)\s*(?:ay|is|ng|na)?\s*(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?).*(?:cash|tendered|bayad|inabot)\s*(?:ay|is|ng|na)?\s*(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?)',
    );

    double cash = 0;
    double bill = 0;

    final matchCashBill = cashThenBill.firstMatch(text);
    final matchBillCash = billThenCash.firstMatch(text);

    if (matchCashBill != null) {
      cash = double.tryParse(matchCashBill.group(1)!.replaceAll(',', '')) ?? 0;
      bill = double.tryParse(matchCashBill.group(2)!.replaceAll(',', '')) ?? 0;
    } else if (matchBillCash != null) {
      bill = double.tryParse(matchBillCash.group(1)!.replaceAll(',', '')) ?? 0;
      cash = double.tryParse(matchBillCash.group(2)!.replaceAll(',', '')) ?? 0;
    } else {
      // General 2-number extraction
      final numberPattern = RegExp(r'(\d+(?:,\d{3})*(?:\.\d+)?)');
      final matches = numberPattern.allMatches(text).toList();
      if (matches.length < 2) return null;

      final num1 =
          double.tryParse(matches[0].group(1)!.replaceAll(',', '')) ?? 0;
      final num2 =
          double.tryParse(matches[1].group(1)!.replaceAll(',', '')) ?? 0;

      if (num1 == 0 || num2 == 0) return null;

      // Default: assuming larger is cash tendered unless specified
      cash = num1 > num2 ? num1 : num2;
      bill = num1 > num2 ? num2 : num1;
    }

    if (cash == 0 || bill == 0) return null;

    final change = cash - bill;

    if (change < 0) {
      final shortage = -change;
      return CalculatorResult(
        success: true,
        expression: 'Kulang: ${_currencyFormat.format(cash)} vs ${_currencyFormat.format(bill)}',
        value: change,
        formattedValue: 'Kulang ${_currencyFormat.format(shortage)}',
        breakdown:
            '⚠️ Insufficient payment (Kulang)! Short by ${_currencyFormat.format(shortage)} (Tendered: ${_currencyFormat.format(cash)} | Total Bill: ${_currencyFormat.format(bill)})',
        category: CalculatorCategory.change,
      );
    }

    return CalculatorResult(
      success: true,
      expression: 'Sukli: ${_currencyFormat.format(cash)} - ${_currencyFormat.format(bill)}',
      value: change,
      formattedValue: _currencyFormat.format(change),
      breakdown:
          'Tendered: ${_currencyFormat.format(cash)} | Total Bill: ${_currencyFormat.format(bill)}',
      category: CalculatorCategory.change,
    );
  }

  // ── 4. Markup Evaluator ────────────────────────────────────────────────
  static CalculatorResult? _evalMarkup(String rawText) {
    var text = rawText
        .replaceAll('percent', '%')
        .replaceAll('porsyento', '%');

    // "markup 30% on 450", "markup 25% sa 500"
    final pattern = RegExp(
      r'(?:markup\s*(?:of|na)?\s*(\d+(?:\.\d+)?)\s*%\s*(?:on|sa|of|for)?\s*(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?))',
    );
    final match = pattern.firstMatch(text);
    if (match != null) {
      final rate = double.tryParse(match.group(1)!) ?? 0;
      final cost = double.tryParse(match.group(2)!.replaceAll(',', '')) ?? 0;
      final markupAmount = cost * (rate / 100);
      final selling = cost + markupAmount;
      return CalculatorResult(
        success: true,
        expression: 'Cost ${_currencyFormat.format(cost)} + $rate% markup',
        value: selling,
        formattedValue: _currencyFormat.format(selling),
        breakdown:
            'Cost: ${_currencyFormat.format(cost)} | Markup ($rate%): +${_currencyFormat.format(markupAmount)} | SRP: ${_currencyFormat.format(selling)}',
        category: CalculatorCategory.markup,
      );
    }
    return null;
  }

  // ── 5. Profit / Margin Evaluator ───────────────────────────────────────
  static CalculatorResult? _evalProfitMargin(String text) {
    // "profit cost 200 sell 350", "cost 200 sell 350", "puhunan 200 benta 350", "puhunan 200 srp 350"
    if (!text.contains('profit') &&
        !text.contains('tubo') &&
        !text.contains('puhunan') &&
        !text.contains('margin') &&
        !text.contains('kita')) {
      return null;
    }

    final costPattern = RegExp(
      r'(?:cost|puhunan|capital)\s*[:=]?\s*(?:is|ay|ng)?\s*(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?)',
    );
    final sellPattern = RegExp(
      r'(?:sell|price|presyo|benta|srp|selling)\s*[:=]?\s*(?:is|ay|ng)?\s*(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?)',
    );

    final costMatch = costPattern.firstMatch(text);
    final sellMatch = sellPattern.firstMatch(text);

    if (costMatch != null && sellMatch != null) {
      final cost =
          double.tryParse(costMatch.group(1)!.replaceAll(',', '')) ?? 0;
      final sell =
          double.tryParse(sellMatch.group(1)!.replaceAll(',', '')) ?? 0;

      final profit = sell - cost;
      final marginPct = sell > 0 ? (profit / sell) * 100 : 0.0;

      return CalculatorResult(
        success: true,
        expression:
            'Profit: ${_currencyFormat.format(sell)} - ${_currencyFormat.format(cost)}',
        value: profit,
        formattedValue: _currencyFormat.format(profit),
        breakdown:
            'Cost: ${_currencyFormat.format(cost)} | Sell: ${_currencyFormat.format(sell)} | Profit Margin: ${marginPct.toStringAsFixed(1)}%',
        category: CalculatorCategory.margin,
      );
    }
    return null;
  }

  // ── 6. Parts + Labor Evaluator ─────────────────────────────────────────
  static CalculatorResult? _evalPartsLabor(String text) {
    if (!text.contains('parts') &&
        !text.contains('pyesa') &&
        !text.contains('part') &&
        !text.contains('labor') &&
        !text.contains('serbisyo') &&
        !text.contains('service')) {
      return null;
    }

    final partsPattern = RegExp(
      r'(?:parts|pyesa|part)\s*[:=]?\s*(?:is|ay|ng)?\s*(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?)',
    );
    final laborPattern = RegExp(
      r'(?:labor|serbisyo|service|gawa)\s*[:=]?\s*(?:is|ay|ng)?\s*(?:₱|p)?\s*(\d+(?:,\d{3})*(?:\.\d+)?)',
    );

    final partsMatch = partsPattern.firstMatch(text);
    final laborMatch = laborPattern.firstMatch(text);

    if (partsMatch != null && laborMatch != null) {
      final parts =
          double.tryParse(partsMatch.group(1)!.replaceAll(',', '')) ?? 0;
      final labor =
          double.tryParse(laborMatch.group(1)!.replaceAll(',', '')) ?? 0;
      final total = parts + labor;

      return CalculatorResult(
        success: true,
        expression:
            'Parts ${_currencyFormat.format(parts)} + Labor ${_currencyFormat.format(labor)}',
        value: total,
        formattedValue: _currencyFormat.format(total),
        breakdown:
            'Parts: ${_currencyFormat.format(parts)} | Labor: ${_currencyFormat.format(labor)} | Total: ${_currencyFormat.format(total)}',
        category: CalculatorCategory.partsLabor,
      );
    }
    return null;
  }

  // ── 7. Math Expression Parser & Evaluator (Shunting-Yard) ──────────────
  static CalculatorResult? _evalMathExpression(String rawQuery) {
    var cleaned = rawQuery.trim().toLowerCase();

    // Strip common question/command prefixes
    final prefixes = [
      'calculate',
      'compute',
      'solve',
      'what is',
      'magkano ang',
      'magkano',
      'kwentahin',
      'ilan ang',
      'how much is',
      'how much',
      'total of',
      'total',
      'sum of',
      'sum',
      'add',
    ];
    for (final p in prefixes) {
      if (cleaned.startsWith(p)) {
        cleaned = cleaned.substring(p.length).trim();
        break;
      }
    }

    // Convert spoken math words into operators
    cleaned = cleaned
        .replaceAll(RegExp(r'\bminus\b|\bless\b|\bbawas sa\b|\bbawas\b'), ' - ')
        .replaceAll(RegExp(r'\bplus\b|\bdagdag sa\b|\bdagdag\b|\band\b'), ' + ')
        .replaceAll(RegExp(r'\btimes\b|\bmultiplied by\b|\bmultiply by\b'), ' * ')
        .replaceAll(RegExp(r'\bdivided by\b|\bdivide by\b|\bover\b|\bhati sa\b'), ' / ')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('₱', '')
        .replaceAll(RegExp(r'\b(?:php|pesos|peso)\b'), '')
        .replaceAll(RegExp(r'(?<=\d),(?=\d)'), '');

    // Replace 'x' or 'X' surrounded by numbers or spaces with '*'
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<=\d|\))\s*[xX]\s*(?=\d|\()'),
      (m) => ' * ',
    );

    // Check if the string contains at least one math operator (+, -, *, /, %) and numbers
    if (!RegExp(r'[\+\-\*\/\%]').hasMatch(cleaned)) return null;
    if (!RegExp(r'\d').hasMatch(cleaned)) return null;

    // Check if it only contains valid math characters: digits, ., +, -, *, /, %, (, ), spaces
    if (!RegExp(r'^[0-9\.\+\-\*\/\%\(\)\s]+$').hasMatch(cleaned.trim())) {
      return null;
    }

    try {
      final value = _evaluateExpression(cleaned);
      final formatted = (value == value.roundToDouble() && value.abs() < 1000000000)
          ? _decimalFormat.format(value.round())
          : _decimalFormat.format(value);

      return CalculatorResult(
        success: true,
        expression: cleaned.trim().replaceAll('*', '×').replaceAll('/', '÷'),
        value: value,
        formattedValue: formatted,
        breakdown: 'Result: $formatted',
        category: CalculatorCategory.math,
      );
    } on FormatException catch (e) {
      if (e.message == 'Division by zero') {
        return CalculatorResult.error(
          cleaned.trim().replaceAll('*', '×').replaceAll('/', '÷'),
          'Cannot divide by zero (Hindi pwedeng hatiin sa zero)',
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Shunting-yard algorithm to parse & evaluate arithmetic expressions.
  static double _evaluateExpression(String expr) {
    final tokens = _tokenize(expr);
    if (tokens.isEmpty) throw const FormatException('Empty expression');

    final values = <double>[];
    final ops = <String>[];

    int precedence(String op) {
      if (op == '+' || op == '-') return 1;
      if (op == '*' || op == '/' || op == '%') return 2;
      return 0;
    }

    void applyOp() {
      if (ops.isEmpty || values.length < 2) {
        throw const FormatException('Invalid expression structure');
      }
      final op = ops.removeLast();
      final b = values.removeLast();
      final a = values.removeLast();
      switch (op) {
        case '+':
          values.add(a + b);
          break;
        case '-':
          values.add(a - b);
          break;
        case '*':
          values.add(a * b);
          break;
        case '/':
          if (b == 0) throw const FormatException('Division by zero');
          values.add(a / b);
          break;
        case '%':
          values.add(a % b);
          break;
        default:
          throw FormatException('Unknown operator $op');
      }
    }

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (double.tryParse(token) != null) {
        values.add(double.parse(token));
      } else if (token == '(') {
        ops.add(token);
      } else if (token == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          applyOp();
        }
        if (ops.isEmpty || ops.last != '(') {
          throw const FormatException('Mismatched parentheses');
        }
        ops.removeLast(); // pop '('
      } else if (['+', '-', '*', '/', '%'].contains(token)) {
        // Handle unary minus: if at start or immediately after '(' or operator
        if (token == '-' &&
            (i == 0 || ['(', '+', '-', '*', '/', '%'].contains(tokens[i - 1]))) {
          if (i + 1 < tokens.length && double.tryParse(tokens[i + 1]) != null) {
            values.add(-double.parse(tokens[i + 1]));
            i++;
            continue;
          }
        }

        while (ops.isNotEmpty &&
            ops.last != '(' &&
            precedence(ops.last) >= precedence(token)) {
          applyOp();
        }
        ops.add(token);
      }
    }

    while (ops.isNotEmpty) {
      if (ops.last == '(' || ops.last == ')') {
        throw const FormatException('Mismatched parentheses');
      }
      applyOp();
    }

    if (values.length != 1) {
      throw const FormatException('Malformed expression');
    }

    return values.single;
  }

  static List<String> _tokenize(String expr) {
    final tokens = <String>[];
    int i = 0;
    final clean = expr.replaceAll(' ', '');

    while (i < clean.length) {
      final ch = clean[i];

      if (['+', '-', '*', '/', '%', '(', ')'].contains(ch)) {
        tokens.add(ch);
        i++;
      } else if (RegExp(r'[0-9\.]').hasMatch(ch)) {
        int start = i;
        while (i < clean.length && RegExp(r'[0-9\.]').hasMatch(clean[i])) {
          i++;
        }
        tokens.add(clean.substring(start, i));
      } else {
        i++;
      }
    }

    return tokens;
  }
}
