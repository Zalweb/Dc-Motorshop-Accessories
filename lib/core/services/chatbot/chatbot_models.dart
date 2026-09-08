import '../../../data/models/product.dart';

enum ChatbotIntentType {
  calculator,
  dailySales,
  dailyProfit,
  dailyExpenses,
  financialOverview,
  checkStock,
  checkLowStock,
  priceLookup,
  help,
  greeting,
  search,
}

enum CalculatorCategory {
  math,
  discount,
  change,
  margin,
  markup,
  partsLabor,
}

class CalculatorResult {
  final bool success;
  final String expression;
  final double value;
  final String formattedValue;
  final String breakdown;
  final CalculatorCategory category;
  final String? errorMessage;

  const CalculatorResult({
    required this.success,
    required this.expression,
    required this.value,
    required this.formattedValue,
    required this.breakdown,
    required this.category,
    this.errorMessage,
  });

  factory CalculatorResult.error(String expression, String message) {
    return CalculatorResult(
      success: false,
      expression: expression,
      value: 0,
      formattedValue: 'Error',
      breakdown: message,
      category: CalculatorCategory.math,
      errorMessage: message,
    );
  }
}

class FinancialSummaryData {
  final double revenue;
  final int salesCount;
  final double cogs;
  final double grossProfit;
  final double profitMargin;
  final double expenses;
  final double netProfit;
  final List<String> topExpenseLabels;

  const FinancialSummaryData({
    required this.revenue,
    required this.salesCount,
    required this.cogs,
    required this.grossProfit,
    required this.profitMargin,
    required this.expenses,
    required this.netProfit,
    this.topExpenseLabels = const [],
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatbotIntentType intentType;
  final CalculatorResult? calculatorResult;
  final List<Product>? products;
  final FinancialSummaryData? financialSummary;
  final List<String> actionChips;
  final String? rawQuery;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.intentType = ChatbotIntentType.search,
    this.calculatorResult,
    this.products,
    this.financialSummary,
    this.actionChips = const [],
    this.rawQuery,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    ChatbotIntentType? intentType,
    CalculatorResult? calculatorResult,
    List<Product>? products,
    FinancialSummaryData? financialSummary,
    List<String>? actionChips,
    String? rawQuery,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      intentType: intentType ?? this.intentType,
      calculatorResult: calculatorResult ?? this.calculatorResult,
      products: products ?? this.products,
      financialSummary: financialSummary ?? this.financialSummary,
      actionChips: actionChips ?? this.actionChips,
      rawQuery: rawQuery ?? this.rawQuery,
    );
  }
}
