import 'package:intl/intl.dart';

import '../../utils/stock_health.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/product.dart';
import '../../../data/models/sale.dart';
import 'chatbot_models.dart';
import 'math_evaluator.dart';

class ChatbotEngine {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  /// Processes user text input against current shop database state and returns a response [ChatMessage].
  static ChatMessage processMessage({
    required String input,
    required List<Product> products,
    required List<Sale> sales,
    required List<Expense> expenses,
  }) {
    final query = input.trim();
    final lower = query.toLowerCase();

    // 1. Check for Math / Calculation intents FIRST
    final mathResult = MathEvaluator.tryEvaluate(query);
    if (mathResult != null) {
      return _buildCalculatorResponse(mathResult, query);
    }

    // 2. Sales & Financial Intents (Yesterday vs Today)
    if (_isYesterdaySalesQuery(lower)) {
      return _buildYesterdaySalesResponse(sales, expenses, query);
    }

    if (_isDailySalesQuery(lower)) {
      return _buildDailySalesResponse(sales, expenses, query);
    }

    if (_isDailyProfitQuery(lower)) {
      return _buildDailyProfitResponse(sales, expenses, query);
    }

    if (_isDailyExpensesQuery(lower)) {
      return _buildDailyExpensesResponse(expenses, query);
    }

    if (_isFinancialOverviewQuery(lower)) {
      return _buildFinancialOverviewResponse(sales, expenses, query);
    }

    // 3. Low Stock / Out of Stock Intent
    if (_isLowStockQuery(lower)) {
      return _buildLowStockResponse(products, query);
    }

    // 4. Stock Check for Specific Item or Generic Stock Check
    if (_isGenericStockCheckQuery(lower)) {
      return _buildGenericStockCheckResponse(products, query);
    }

    if (_isStockCheckQuery(lower)) {
      final itemQuery = _extractStockQuery(lower);
      return _buildStockCheckResponse(itemQuery, products, query);
    }

    // 5. Price Lookup Intent
    if (_isPriceLookupQuery(lower)) {
      final itemQuery = _extractPriceQuery(lower);
      return _buildPriceLookupResponse(itemQuery, products, query);
    }

    // 6. Help Intent
    if (_isHelpQuery(lower)) {
      return _buildHelpResponse(query);
    }

    // 7. Greeting & Pleasantries Intent
    if (_isGreetingQuery(lower)) {
      return _buildGreetingResponse(query);
    }

    // 8. Default: Search Products in Inventory
    return _buildSearchFallbackResponse(query, products);
  }

  // ── Intent Classifiers ───────────────────────────────────────────────

  static bool _isYesterdaySalesQuery(String text) {
    const patterns = [
      'kahapon',
      'yesterday',
      'sales kahapon',
      'benta kahapon',
      'magkano benta kahapon',
      'yesterday sales',
      'yesterdays sales',
      "yesterday's sales",
      'sales yesterday',
    ];
    return patterns.any((p) => text.contains(p));
  }

  static bool _isDailySalesQuery(String text) {
    if (text.contains('kahapon') || text.contains('yesterday')) return false;

    const patterns = [
      'magkano benta ngayon',
      'magkano benta natin ngayon',
      'magkano benta natin',
      'magkano benta',
      'benta ngayon',
      'how much did we sell today',
      'how much we sold today',
      'how much sales today',
      'today sales',
      'todays sales',
      "today's sales",
      'total sales today',
      'sales today',
      'daily sales',
      'total revenue today',
      'today revenue',
      'revenue today',
      'benta for today',
      'today\'s revenue',
    ];
    return patterns.any((p) => text.contains(p) || text == p);
  }

  static bool _isDailyProfitQuery(String text) {
    const patterns = [
      'magkano kita ngayon',
      'magkano kita natin ngayon',
      'kita ngayon',
      'tubo ngayon',
      'tubo natin ngayon',
      'today profit',
      'todays profit',
      "today's profit",
      'daily profit',
      'profit today',
      'profit margin today',
      'net profit today',
      'gross profit today',
    ];
    return patterns.any((p) => text.contains(p) || text == p);
  }

  static bool _isDailyExpensesQuery(String text) {
    const patterns = [
      'magkano gastos ngayon',
      'gastos ngayon',
      'mga gastos ngayon',
      'today expense',
      'today expenses',
      'todays expenses',
      "today's expenses",
      'daily expenses',
      'expenses today',
      'total expenses today',
      'mga nagastos ngayon',
    ];
    return patterns.any((p) => text.contains(p) || text == p);
  }

  static bool _isFinancialOverviewQuery(String text) {
    const patterns = [
      'financial overview',
      'financial summary',
      'summary today',
      'kamusta benta',
      'kamusta negosyo',
      'overall sales',
      'shop status',
    ];
    return patterns.any((p) => text.contains(p) || text == p);
  }

  static bool _isLowStockQuery(String text) {
    const patterns = [
      'anong mga low stock',
      'anong low stock',
      'anong mga paubos na',
      'anong paubos na',
      'mga paubos na gamit',
      'mga paubos na pyesa',
      'mga paubos na',
      'paubos na stock',
      'paubos na',
      'what is low on stock',
      'what items are low on stock',
      'what is low stock',
      'show low stock',
      'check low stock',
      'low stock items',
      'low stock alert',
      'low stock',
      'out of stock',
      'critical stock',
      'restock list',
      'items to restock',
      'zero stock',
      'ubos na stock',
      'ubos na',
      'walang stock',
    ];
    return patterns.any((p) => text.contains(p) || text == p);
  }

  static bool _isGenericStockCheckQuery(String text) {
    const genericQueries = [
      'check product stock',
      'check stock',
      'stock check',
      'inventory stock',
      'check inventory',
      'tingnan ang stock',
      'product stock',
    ];
    return genericQueries.contains(text.trim());
  }

  static bool _isStockCheckQuery(String text) {
    const prefixes = [
      'how many',
      'how much stock of',
      'how much stock for',
      'check stock of',
      'check stock for',
      'check stock',
      'stock of',
      'stock for',
      'stock ng',
      'stocks ng',
      'do we have',
      'ilan pa ang stock ng',
      'ilan pa ang stock',
      'ilan pa stock ng',
      'ilan pa ang',
      'ilan pa',
      'ilan na lang ang',
      'ilan na lang',
      'may stock pa ba ng',
      'may stock pa ba',
      'meron pa bang',
      'meron pa ba',
      'meron bang',
      'mayroon pa bang',
      'mayroon pa ba',
      'mayroon bang',
      'may stock ba',
      'may',
    ];
    if (prefixes.any((p) => text.startsWith(p))) return true;

    // Suffix checks: "motul stock", "spark plug stock", "aerox belt stocks"
    const suffixes = [' stock', ' stocks', ' inventory', ' left', ' available'];
    return suffixes.any((s) => text.endsWith(s));
  }

  static String _extractStockQuery(String text) {
    const prefixes = [
      'how many',
      'how much stock of',
      'how much stock for',
      'check stock of',
      'check stock for',
      'check stock',
      'stock of',
      'stock for',
      'stock ng',
      'stocks ng',
      'do we have',
      'ilan pa ang stock ng',
      'ilan pa ang stock',
      'ilan pa stock ng',
      'ilan pa ang',
      'ilan pa',
      'ilan na lang ang',
      'ilan na lang',
      'may stock pa ba ng',
      'may stock pa ba',
      'meron pa bang',
      'meron pa ba',
      'meron bang',
      'mayroon pa bang',
      'mayroon pa ba',
      'mayroon bang',
      'may stock ba',
    ];

    var clean = text;
    for (final p in prefixes) {
      if (clean.startsWith(p)) {
        clean = clean.substring(p.length).trim();
        break;
      }
    }

    // Strip suffixes
    clean = clean
        .replaceAll(RegExp(r'\b(stock|stocks|inventory|left|remaining|pa|available|ba|po|ang|the)\b'), '')
        .replaceAll('?', '')
        .trim();

    return clean.isNotEmpty ? clean : text;
  }

  static bool _isPriceLookupQuery(String text) {
    const prefixes = [
      'how much is',
      'how much for',
      'how much',
      'magkano ang presyo ng',
      'magkano presyo ng',
      'magkano presyo',
      'magkano ang',
      'magkano pyesa ng',
      'magkano',
      'presyo ng',
      'price of',
      'price for',
    ];
    if (prefixes.any((p) => text.startsWith(p))) return true;

    const suffixes = [' price', ' presyo', ' magkano'];
    return suffixes.any((s) => text.endsWith(s));
  }

  static String _extractPriceQuery(String text) {
    const prefixes = [
      'magkano ang presyo ng',
      'magkano presyo ng',
      'magkano presyo',
      'magkano ang',
      'magkano pyesa ng',
      'presyo ng',
      'how much is',
      'how much for',
      'how much',
      'magkano',
      'price of',
      'price for',
    ];
    var clean = text;
    for (final p in prefixes) {
      if (clean.startsWith(p)) {
        clean = clean.substring(p.length).trim();
        break;
      }
    }

    clean = clean
        .replaceAll(RegExp(r'\b(price|presyo|magkano|ba|po|ito|ang|the)\b'), '')
        .replaceAll('?', '')
        .trim();

    return clean.isNotEmpty ? clean : text;
  }

  static bool _isHelpQuery(String text) {
    return text.contains('help') ||
        text.contains('tulong') ||
        text.contains('what can you do') ||
        text.contains('ano kaya mong gawin') ||
        text.contains('features') ||
        text.contains('capabilities') ||
        text.contains('guide') ||
        text.contains('commands') ||
        text.contains('quick help');
  }

  static bool _isGreetingQuery(String text) {
    const greetings = [
      'hello',
      'hi',
      'hey',
      'kamusta',
      'kumusta',
      'good morning',
      'magandang umaga',
      'good afternoon',
      'magandang hapon',
      'good evening',
      'magandang gabi',
      'salamat',
      'thank you',
      'thanks',
    ];
    return greetings.any((g) => text == g || text.startsWith('$g '));
  }

  // ── Response Builders ────────────────────────────────────────────────

  static ChatMessage _buildCalculatorResponse(
      CalculatorResult result, String query) {
    String replyText;
    switch (result.category) {
      case CalculatorCategory.discount:
        replyText =
            'Discount computed: ${result.formattedValue} (${result.breakdown})';
        break;
      case CalculatorCategory.change:
        replyText = result.value < 0
            ? '⚠️ ${result.breakdown}'
            : 'Sukli to return: ${result.formattedValue} (${result.breakdown})';
        break;
      case CalculatorCategory.markup:
        replyText =
            'Suggested SRP: ${result.formattedValue} (${result.breakdown})';
        break;
      case CalculatorCategory.margin:
        replyText =
            'Net Profit: ${result.formattedValue} (${result.breakdown})';
        break;
      case CalculatorCategory.partsLabor:
        replyText =
            'Parts + Labor Sum: ${result.formattedValue} (${result.breakdown})';
        break;
      case CalculatorCategory.math:
        replyText = result.errorMessage != null
            ? 'Math error: ${result.errorMessage}'
            : 'The answer is ${result.formattedValue} (${result.expression})';
        break;
    }

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      intentType: ChatbotIntentType.calculator,
      calculatorResult: result,
      rawQuery: query,
      actionChips: [
        '💰 Today\'s Sales',
        '⚠️ Low Stock Alert',
        '📦 Check Product Stock',
      ],
    );
  }

  static ChatMessage _buildDailySalesResponse(
    List<Sale> sales,
    List<Expense> expenses,
    String query,
  ) {
    final now = DateTime.now();
    // Exclude unpaid sales to match dashboard & reports realized revenue
    final todaySales = sales.where((s) {
      final d = s.createdAt.toLocal();
      return s.status != 'unpaid' &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).toList();

    final revenue = todaySales.fold<double>(0.0, (sum, s) => sum + s.total);
    final count = todaySales.length;

    // COGS and gross profit
    double cogs = 0.0;
    for (final sale in todaySales) {
      for (final item in sale.items) {
        cogs += (item.unitCost * item.quantity);
      }
    }
    final grossProfit = revenue - cogs;
    final profitMargin = revenue > 0 ? (grossProfit / revenue) * 100 : 0.0;

    // Today's expenses
    final todayExpenses = expenses.where((e) {
      if (!e.includeInCalculations) return false;
      final d = e.createdAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    final totalExpenses =
        todayExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final netProfit = grossProfit - totalExpenses;

    final summary = FinancialSummaryData(
      revenue: revenue,
      salesCount: count,
      cogs: cogs,
      grossProfit: grossProfit,
      profitMargin: profitMargin,
      expenses: totalExpenses,
      netProfit: netProfit,
      topExpenseLabels: todayExpenses.take(3).map((e) => e.label).toList(),
    );

    final String replyText;
    if (count == 0) {
      replyText =
          'No sales recorded yet today. Ready to ring up your first transaction!';
    } else {
      final avg = revenue / count;
      replyText =
          'Today\'s sales total is ${_currencyFormat.format(revenue)} across $count transaction${count == 1 ? '' : 's'} (average ticket: ${_currencyFormat.format(avg)}).';
    }

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      intentType: ChatbotIntentType.dailySales,
      financialSummary: summary,
      rawQuery: query,
      actionChips: [
        '📈 Today\'s Profit',
        '💸 Today\'s Expenses',
        '⚠️ Low Stock Alert',
        '🧮 Calculator',
      ],
    );
  }

  static ChatMessage _buildYesterdaySalesResponse(
    List<Sale> sales,
    List<Expense> expenses,
    String query,
  ) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final ySales = sales.where((s) {
      final d = s.createdAt.toLocal();
      return s.status != 'unpaid' &&
          d.year == yesterday.year &&
          d.month == yesterday.month &&
          d.day == yesterday.day;
    }).toList();

    final revenue = ySales.fold<double>(0.0, (sum, s) => sum + s.total);
    final count = ySales.length;

    double cogs = 0.0;
    for (final sale in ySales) {
      for (final item in sale.items) {
        cogs += (item.unitCost * item.quantity);
      }
    }
    final grossProfit = revenue - cogs;
    final profitMargin = revenue > 0 ? (grossProfit / revenue) * 100 : 0.0;

    final yExpenses = expenses.where((e) {
      if (!e.includeInCalculations) return false;
      final d = e.createdAt.toLocal();
      return d.year == yesterday.year &&
          d.month == yesterday.month &&
          d.day == yesterday.day;
    }).toList();
    final totalExpenses =
        yExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final netProfit = grossProfit - totalExpenses;

    final summary = FinancialSummaryData(
      revenue: revenue,
      salesCount: count,
      cogs: cogs,
      grossProfit: grossProfit,
      profitMargin: profitMargin,
      expenses: totalExpenses,
      netProfit: netProfit,
      topExpenseLabels: yExpenses.take(3).map((e) => e.label).toList(),
    );

    final String replyText = count == 0
        ? 'No sales were recorded yesterday.'
        : 'Yesterday\'s sales totaled ${_currencyFormat.format(revenue)} across $count transaction${count == 1 ? '' : 's'}.';

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      intentType: ChatbotIntentType.dailySales,
      financialSummary: summary,
      rawQuery: query,
      actionChips: [
        '💰 Today\'s Sales',
        '📈 Today\'s Profit',
        '⚠️ Low Stock Alert',
      ],
    );
  }

  static ChatMessage _buildDailyProfitResponse(
    List<Sale> sales,
    List<Expense> expenses,
    String query,
  ) {
    final now = DateTime.now();
    final todaySales = sales.where((s) {
      final d = s.createdAt.toLocal();
      return s.status != 'unpaid' &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).toList();

    final revenue = todaySales.fold<double>(0.0, (sum, s) => sum + s.total);
    double cogs = 0.0;
    for (final sale in todaySales) {
      for (final item in sale.items) {
        cogs += (item.unitCost * item.quantity);
      }
    }
    final grossProfit = revenue - cogs;
    final profitMargin = revenue > 0 ? (grossProfit / revenue) * 100 : 0.0;

    final todayExpenses = expenses.where((e) {
      if (!e.includeInCalculations) return false;
      final d = e.createdAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    final totalExpenses =
        todayExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final netProfit = grossProfit - totalExpenses;

    final summary = FinancialSummaryData(
      revenue: revenue,
      salesCount: todaySales.length,
      cogs: cogs,
      grossProfit: grossProfit,
      profitMargin: profitMargin,
      expenses: totalExpenses,
      netProfit: netProfit,
      topExpenseLabels: todayExpenses.take(3).map((e) => e.label).toList(),
    );

    final replyText = revenue == 0
        ? 'No sales registered today to calculate profit. Make a sale to see real-time margins!'
        : 'Today\'s gross profit is ${_currencyFormat.format(grossProfit)} (${profitMargin.toStringAsFixed(1)}% margin). '
            'After deducting ${_currencyFormat.format(totalExpenses)} in expenses, net profit is ${_currencyFormat.format(netProfit)}.';

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      intentType: ChatbotIntentType.dailyProfit,
      financialSummary: summary,
      rawQuery: query,
      actionChips: [
        '💰 Today\'s Sales',
        '💸 Today\'s Expenses',
        '⚠️ Low Stock Alert',
      ],
    );
  }

  static ChatMessage _buildDailyExpensesResponse(
    List<Expense> expenses,
    String query,
  ) {
    final now = DateTime.now();
    final todayExpenses = expenses.where((e) {
      if (!e.includeInCalculations) return false;
      final d = e.createdAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();

    final total =
        todayExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final count = todayExpenses.length;

    final replyText = count == 0
        ? 'No expenses recorded today. All clear!'
        : 'Total expenses recorded today are ${_currencyFormat.format(total)} across $count item${count == 1 ? '' : 's'}.';

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      intentType: ChatbotIntentType.dailyExpenses,
      financialSummary: FinancialSummaryData(
        revenue: 0,
        salesCount: 0,
        cogs: 0,
        grossProfit: 0,
        profitMargin: 0,
        expenses: total,
        netProfit: -total,
        topExpenseLabels: todayExpenses.map((e) => e.label).toList(),
      ),
      rawQuery: query,
      actionChips: [
        '💰 Today\'s Sales',
        '📈 Today\'s Profit',
        '⚠️ Low Stock Alert',
      ],
    );
  }

  static ChatMessage _buildFinancialOverviewResponse(
    List<Sale> sales,
    List<Expense> expenses,
    String query,
  ) {
    return _buildDailySalesResponse(sales, expenses, query).copyWith(
      intentType: ChatbotIntentType.financialOverview,
    );
  }

  static ChatMessage _buildLowStockResponse(
    List<Product> products,
    String query,
  ) {
    final lowStockItems = products.where((p) {
      return !p.isService && p.effectiveStockQty <= lowStockThreshold;
    }).toList();

    lowStockItems
        .sort((a, b) => a.effectiveStockQty.compareTo(b.effectiveStockQty));

    if (lowStockItems.isEmpty) {
      return ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text:
            'All products are well-stocked! There are 0 items low or critical on stock right now.',
        isUser: false,
        timestamp: DateTime.now(),
        intentType: ChatbotIntentType.checkLowStock,
        products: const [],
        rawQuery: query,
        actionChips: [
          '💰 Today\'s Sales',
          '📦 Check Product Stock',
          '🧮 Calculator',
        ],
      );
    }

    final criticalCount = lowStockItems
        .where((p) => p.effectiveStockQty <= criticalStockThreshold)
        .length;

    final replyText =
        'Found ${lowStockItems.length} item(s) low on stock ($criticalCount critical). Here are the items that need restock:';

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      intentType: ChatbotIntentType.checkLowStock,
      products: lowStockItems,
      rawQuery: query,
      actionChips: [
        '💰 Today\'s Sales',
        '📦 Check Product Stock',
        '💡 Quick Help',
      ],
    );
  }

  static ChatMessage _buildGenericStockCheckResponse(
    List<Product> products,
    String query,
  ) {
    final physical = products.where((p) => !p.isService).toList();
    physical.sort((a, b) => a.effectiveStockQty.compareTo(b.effectiveStockQty));

    const replyText =
        'To check product stock, tell me the part name! For example: "How many Motul left?" or "spark plug stock". Here are your current items:';

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      intentType: ChatbotIntentType.checkStock,
      products: physical.take(6).toList(),
      rawQuery: query,
      actionChips: [
        '⚠️ Low Stock Alert',
        '📦 Motul oil stock',
        '💰 Today\'s Sales',
      ],
    );
  }

  static ChatMessage _buildStockCheckResponse(
    String itemQuery,
    List<Product> products,
    String query,
  ) {
    final matches = _searchProducts(itemQuery, products);

    if (matches.isEmpty) {
      return ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text:
            'No products found in inventory matching "$itemQuery". Check spelling or try another keyword.',
        isUser: false,
        timestamp: DateTime.now(),
        intentType: ChatbotIntentType.checkStock,
        products: const [],
        rawQuery: query,
        actionChips: [
          '⚠️ Low Stock Alert',
          '💰 Today\'s Sales',
          '💡 Quick Help',
        ],
      );
    }

    final top = matches.first;
    final replyText = matches.length == 1
        ? '${top.name}: ${top.effectiveStockQty} in stock, priced at ${_currencyFormat.format(top.sellingPrice)}.'
        : 'Found ${matches.length} products matching "$itemQuery":';

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      intentType: ChatbotIntentType.checkStock,
      products: matches,
      rawQuery: query,
      actionChips: [
        '⚠️ Low Stock Alert',
        '💰 Today\'s Sales',
        '🧮 Calculator',
      ],
    );
  }

  static ChatMessage _buildPriceLookupResponse(
    String itemQuery,
    List<Product> products,
    String query,
  ) {
    final matches = _searchProducts(itemQuery, products);

    if (matches.isEmpty) {
      return ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text:
            'Could not find price for "$itemQuery". No matching products in inventory.',
        isUser: false,
        timestamp: DateTime.now(),
        intentType: ChatbotIntentType.priceLookup,
        products: const [],
        rawQuery: query,
        actionChips: [
          '⚠️ Low Stock Alert',
          '💰 Today\'s Sales',
        ],
      );
    }

    final top = matches.first;
    final priceStr = top.hasVariants && top.variants.isNotEmpty
        ? '${_currencyFormat.format(top.minSellingPrice)} - ${_currencyFormat.format(top.maxSellingPrice)}'
        : _currencyFormat.format(top.sellingPrice);

    final replyText = matches.length == 1
        ? 'The selling price for ${top.name} is $priceStr (${top.effectiveStockQty} currently in stock).'
        : 'Found ${matches.length} products matching "$itemQuery" with prices:';

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      intentType: ChatbotIntentType.priceLookup,
      products: matches,
      rawQuery: query,
      actionChips: [
        '💰 Today\'s Sales',
        '⚠️ Low Stock Alert',
        '🧮 Calculator',
      ],
    );
  }

  static ChatMessage _buildHelpResponse(String query) {
    const helpText =
        'Here is what I can do for you in DC Motorshop:\n\n'
        '🧮 Quick Math & Calculator\n'
        '• "10% off on 1500" or "1500 less 10%" (Discounts)\n'
        '• "sukli sa 1000 kung 750" or "sukli 1000 - 680" (Change)\n'
        '• "parts: 850 labor: 300" (Parts + Labor total)\n'
        '• "4 x 280", "500 minus 320", "(120 * 2) + 350" (Arithmetic)\n\n'
        '📦 Stock & Price Lookup\n'
        '• "How many Motul left?" or "spark plug stock"\n'
        '• "How much is Aerox belt?" or "presyo ng gulong"\n'
        '• "What items are low on stock?" or "paubos na"\n\n'
        '💰 Sales & Finances\n'
        '• "Magkano benta ngayon?" (Today\'s Revenue)\n'
        '• "Magkano benta kahapon?" (Yesterday\'s Revenue)\n'
        '• "Today\'s profit" (Gross & Net profit)\n'
        '• "Today\'s expenses" (Recorded costs)';

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: helpText,
      isUser: false,
      timestamp: DateTime.now(),
      intentType: ChatbotIntentType.help,
      rawQuery: query,
      actionChips: [
        '💰 Today\'s Sales',
        '⚠️ Low Stock Alert',
        '🧮 10% off 1500',
        '📦 Motul oil stock',
      ],
    );
  }

  static ChatMessage _buildGreetingResponse(String query) {
    const greetingText =
        'Kumusta! Ako ang iyong DC Motorshop AI Assistant. '
        'Maaari mo akong tanungin tungkol sa benta ngayon, mag-check ng stock ng pyesa, '
        'magkwenta ng sukli o discounts, o humingi ng tulong anumang oras.';

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: greetingText,
      isUser: false,
      timestamp: DateTime.now(),
      intentType: ChatbotIntentType.greeting,
      rawQuery: query,
      actionChips: [
        '💰 Today\'s Sales',
        '⚠️ Low Stock Alert',
        '🧮 10% off 1500',
        '📦 Check Product Stock',
      ],
    );
  }

  static ChatMessage _buildSearchFallbackResponse(
    String query,
    List<Product> products,
  ) {
    final matches = _searchProducts(query, products);

    if (matches.isNotEmpty) {
      return ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: 'Found ${matches.length} product(s) matching "$query":',
        isUser: false,
        timestamp: DateTime.now(),
        intentType: ChatbotIntentType.search,
        products: matches,
        rawQuery: query,
        actionChips: [
          '💰 Today\'s Sales',
          '⚠️ Low Stock Alert',
          '🧮 Calculator',
        ],
      );
    }

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text:
          'I could not find matching products or commands for "$query". '
          'Try asking about today\'s sales ("benta ngayon"), low stock items ("paubos na"), or type a math formula like "10% off 1500".',
      isUser: false,
      timestamp: DateTime.now(),
      intentType: ChatbotIntentType.help,
      rawQuery: query,
      actionChips: [
        '💰 Today\'s Sales',
        '⚠️ Low Stock Alert',
        '🧮 10% off 1500',
        '💡 Quick Help',
      ],
    );
  }

  static List<Product> _searchProducts(String query, List<Product> products) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return const [];

    // Strip stopwords that indicate intent rather than product name
    const stopWords = {
      'stock',
      'stocks',
      'inventory',
      'check',
      'left',
      'available',
      'price',
      'presyo',
      'magkano',
      'pyesa',
      'item',
      'product',
      'ng',
      'sa',
      'ang',
      'for',
      'of',
      'ba',
      'po',
    };

    final allWords =
        q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final contentWords =
        allWords.where((w) => !stopWords.contains(w)).toList();
    final effectiveWords = contentWords.isNotEmpty ? contentWords : allWords;
    final cleanQ = effectiveWords.join(' ');

    final matches = products.where((p) {
      final name = p.name.toLowerCase();
      final brand = p.brand?.toLowerCase() ?? '';
      final category = p.category?.toLowerCase() ?? '';
      final part = p.partNumber?.toLowerCase() ?? '';
      final barcode = p.barcode?.toLowerCase() ?? '';
      final combined = '$name $brand $category $part $barcode';

      // Direct full query substring match
      if (combined.contains(q) || combined.contains(cleanQ)) return true;

      // Multi-word match: all effective words in query appear in the product
      if (effectiveWords.isNotEmpty &&
          effectiveWords.every((w) => combined.contains(w))) {
        return true;
      }

      return false;
    }).toList();

    // Sort by relevance:
    // 1. Exact query match in name
    // 2. Name starts with clean query
    // 3. Name contains clean query
    // 4. Higher effective stock
    matches.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();

      final aExact = aName == cleanQ;
      final bExact = bName == cleanQ;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      final aStarts = aName.startsWith(cleanQ);
      final bStarts = bName.startsWith(cleanQ);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      final aContains = aName.contains(cleanQ);
      final bContains = bName.contains(cleanQ);
      if (aContains && !bContains) return -1;
      if (!aContains && bContains) return 1;

      return aName.compareTo(bName);
    });

    return matches;
  }
}
