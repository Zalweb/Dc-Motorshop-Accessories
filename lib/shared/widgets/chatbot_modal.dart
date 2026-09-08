import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/services/chatbot/chatbot_engine.dart';
import '../../core/services/chatbot/chatbot_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/stock_health.dart';
import '../../data/models/product.dart';

class ChatbotModal extends ConsumerStatefulWidget {
  final ValueChanged<String>? onSearchApplied;
  final String? initialQuery;

  const ChatbotModal({
    super.key,
    this.onSearchApplied,
    this.initialQuery,
  });

  /// Displays the interactive chatbot as a responsive dialog on Web/Desktop
  /// or a modal bottom sheet on Mobile, synced above the navigation bar.
  static Future<void> show(
    BuildContext context, {
    ValueChanged<String>? onSearchApplied,
    String? initialQuery,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
            child: ChatbotModal(
              onSearchApplied: onSearchApplied,
              initialQuery: initialQuery,
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: AppColors.bgSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.90,
          child: ChatbotModal(
            onSearchApplied: onSearchApplied,
            initialQuery: initialQuery,
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<ChatbotModal> createState() => _ChatbotModalState();
}

class _ChatbotModalState extends ConsumerState<ChatbotModal> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  final List<ChatMessage> _messages = [];

  static const List<({String label, String query, IconData icon, String subtitle})> _quickActions = [
    (
      label: "Today's Sales",
      query: "Today's sales",
      icon: Icons.trending_up_rounded,
      subtitle: "Revenue, orders & tickets",
    ),
    (
      label: "Today's Profit",
      query: "Today's profit",
      icon: Icons.query_stats_rounded,
      subtitle: "Gross & net margins",
    ),
    (
      label: "Low Stock Alert",
      query: "Low stock alert",
      icon: Icons.warning_amber_rounded,
      subtitle: "Items below reorder point",
    ),
    (
      label: "10% off 1500",
      query: "10% off 1500",
      icon: Icons.percent_rounded,
      subtitle: "Quick discount calculation",
    ),
    (
      label: "Sukli 1000 - 680",
      query: "sukli 1000 - 680",
      icon: Icons.payments_outlined,
      subtitle: "Change calculator",
    ),
    (
      label: "Motul Stock",
      query: "Motul oil stock",
      icon: Icons.inventory_2_outlined,
      subtitle: "Find oil availability",
    ),
    (
      label: "Today's Expenses",
      query: "Today's expenses",
      icon: Icons.receipt_long_rounded,
      subtitle: "Recorded store costs",
    ),
    (
      label: "Quick Help",
      query: "Help",
      icon: Icons.help_outline_rounded,
      subtitle: "Commands & syntax guide",
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initial greeting message
    _messages.add(
      ChatMessage(
        id: 'welcome',
        text:
            'Hello! I am your DC Motorshop AI Assistant.\n'
            'I can compute discounts and customer change, check spare parts stock, alert on low inventory, '
            'and calculate today\'s sales and profit.\n\nTap any suggested prompt below or type your question:',
        isUser: false,
        timestamp: DateTime.now(),
        intentType: ChatbotIntentType.greeting,
        actionChips: const [],
      ),
    );

    // If an initial query was passed, execute it
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSendMessage(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _handleSendMessage(String text) {
    final query = text.trim();
    if (query.isEmpty) return;

    _inputController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: query,
          isUser: true,
          timestamp: DateTime.now(),
          rawQuery: query,
        ),
      );
    });
    _scrollToBottom();

    // Pull current data from Riverpod streams
    final products = ref.read(productListStreamProvider).value ?? [];
    final sales = ref.read(saleListStreamProvider).value ?? [];
    final expenses = ref.read(expenseListStreamProvider).value ?? [];

    // Process via ChatbotEngine
    final botResponse = ChatbotEngine.processMessage(
      input: query,
      products: products,
      sales: sales,
      expenses: expenses,
    );

    setState(() {
      _messages.add(botResponse);
    });
    _scrollToBottom();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: AppColors.bgSurface2,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _applyProductSearch(Product product) {
    if (widget.onSearchApplied != null) {
      widget.onSearchApplied!(product.name);
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop();
      context.push(RoutePaths.productDetail, extra: product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = bottomInset > 0
        ? bottomInset + 8
        : (MediaQuery.paddingOf(context).bottom + 10);

    // Keep streams active while modal is mounted
    ref.watch(productListStreamProvider);
    ref.watch(saleListStreamProvider);
    ref.watch(expenseListStreamProvider);

    return Column(
      children: [
        // Drag handle on mobile
        if (!isDesktop) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],

        // ── Chat Header ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF00E5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'DC Motorshop AI',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 6),
                        _AiBadge(),
                      ],
                    ),
                    Text(
                      'POS Assistant • Sales • Stock • Calculator',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Clear Chat History
              IconButton(
                tooltip: 'Clear Chat History',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _messages.clear();
                    _messages.add(
                      ChatMessage(
                        id: 'welcome_cleared',
                        text:
                            'Chat reset! Ask me anything about stock, sales, calculations, or discounts.',
                        isUser: false,
                        timestamp: DateTime.now(),
                        intentType: ChatbotIntentType.greeting,
                      ),
                    );
                  });
                },
              ),

              // Close Button
              IconButton(
                tooltip: 'Close',
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // ── Chat Messages Stream ──────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _messages.length + (_messages.length <= 1 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _messages.length) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              } else {
                return _buildWelcomePromptCards();
              }
            },
          ),
        ),

        // ── Follow-Up Suggestions Bar (Active Only During Chat) ───────
        if (_messages.length > 1) ...[
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickActions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _quickActions[index];
                return ActionChip(
                  avatar: Icon(item.icon, size: 14, color: AppColors.accent),
                  label: Text(
                    item.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: AppColors.bgSurface2,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  onPressed: () => _handleSendMessage(item.query),
                );
              },
            ),
          ),
        ],

        // ── Input Row (Pure Text Chat, Synced with Nav Bar) ───────────
        Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 4,
            bottom: bottomPadding,
          ),
          child: Row(
            children: [
              // Text Input Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface2,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          focusNode: _inputFocusNode,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Ask or calculate (e.g. 10% off 1500)...',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: _handleSendMessage,
                        ),
                      ),
                      if (_inputController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              size: 16, color: AppColors.textSecondary),
                          onPressed: () {
                            _inputController.clear();
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send Button
              IconButton.filled(
                icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () => _handleSendMessage(_inputController.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Message Bubble Widgets ───────────────────────────────────────────

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, Color(0xFF1E60D0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    // Assistant Message
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface2,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bot label & copy action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.smart_toy_outlined,
                              size: 14, color: AppColors.accent),
                          SizedBox(width: 5),
                          Text(
                            'DC Assistant',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _copyToClipboard(msg.text, 'Reply'),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Main Text formatted cleanly
                  _buildFormattedText(msg.text),

                  // ── Specialized Cards ─────────────────────────────────
                  if (msg.calculatorResult != null) ...[
                    const SizedBox(height: 12),
                    _buildCalculatorCard(msg.calculatorResult!),
                  ],

                  if (msg.financialSummary != null) ...[
                    const SizedBox(height: 12),
                    _buildFinancialSummaryCard(msg.financialSummary!),
                  ],

                  if (msg.products != null && msg.products!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildProductsCard(msg.products!),
                  ],
                ],
              ),
            ),

            // Action chips under bot reply
            if (msg.actionChips.isNotEmpty) _buildActionChips(msg.actionChips),
          ],
        ),
      ),
    );
  }

  /// Beautifully arranged prompt cards for the welcome state.
  Widget _buildWelcomePromptCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              'QUICK SUGGESTIONS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 76,
            ),
            itemCount: _quickActions.length,
            itemBuilder: (context, index) {
              final item = _quickActions[index];
              return InkWell(
                onTap: () => _handleSendMessage(item.query),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, size: 16, color: AppColors.accent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionChips(List<String> chips) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips.map((chip) {
            // Clean emoji from label if present
            final cleanLabel = chip.replaceAll(
              RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]', unicode: true),
              '',
            ).trim();

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: AppColors.accent,
                ),
                label: Text(
                  cleanLabel.isNotEmpty ? cleanLabel : chip,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: AppColors.bgSurface2,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onPressed: () => _handleSendMessage(cleanLabel),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFormattedText(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Bullet points (• or - or *)
      if (trimmed.startsWith('•') || trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final content = trimmed.startsWith('•')
            ? trimmed.substring(1).trim()
            : trimmed.substring(2).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Header lines (starts with emoji or ends with :)
      final isEmojiHeader = RegExp(
        r'^[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}]',
        unicode: true,
      ).hasMatch(trimmed);
      if (isEmojiHeader || (trimmed.endsWith(':') && trimmed.length < 40)) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              trimmed,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        );
        continue;
      }

      // Regular text
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // ── Calculator Card ──────────────────────────────────────────────────
  Widget _buildCalculatorCard(CalculatorResult calc) {
    String categoryLabel;
    IconData categoryIcon;
    switch (calc.category) {
      case CalculatorCategory.discount:
        categoryLabel = 'DISCOUNT RESULT';
        categoryIcon = Icons.local_offer_outlined;
        break;
      case CalculatorCategory.change:
        categoryLabel = 'SUKLI (CHANGE)';
        categoryIcon = Icons.payments_outlined;
        break;
      case CalculatorCategory.markup:
        categoryLabel = 'MARKUP SUGGESTION';
        categoryIcon = Icons.trending_up_rounded;
        break;
      case CalculatorCategory.margin:
        categoryLabel = 'PROFIT MARGIN';
        categoryIcon = Icons.query_stats_rounded;
        break;
      case CalculatorCategory.partsLabor:
        categoryLabel = 'PARTS & LABOR TOTAL';
        categoryIcon = Icons.build_circle_outlined;
        break;
      case CalculatorCategory.math:
        categoryLabel = 'CALCULATED VALUE';
        categoryIcon = Icons.calculate_outlined;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(categoryIcon, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                categoryLabel,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  calc.formattedValue,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: 'Copy amount',
                onPressed: () =>
                    _copyToClipboard(calc.formattedValue, 'Amount'),
                style: IconButton.styleFrom(
                  minimumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            calc.breakdown,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Financial Summary Card ───────────────────────────────────────────
  Widget _buildFinancialSummaryCard(FinancialSummaryData summary) {
    final currency = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  size: 14, color: AppColors.profit),
              const SizedBox(width: 6),
              const Text(
                'TODAY\'S FINANCIAL SNAPSHOT',
                style: TextStyle(
                  color: AppColors.profit,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${summary.salesCount} sale${summary.salesCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2x2 grid metrics
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'GROSS REVENUE',
                  value: currency.format(summary.revenue),
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'GROSS PROFIT',
                  value: currency.format(summary.grossProfit),
                  subtitle: '${summary.profitMargin.toStringAsFixed(1)}% margin',
                  color: AppColors.profit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'EXPENSES TODAY',
                  value: currency.format(summary.expenses),
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'NET EARNINGS',
                  value: currency.format(summary.netProfit),
                  color: summary.netProfit >= 0
                      ? AppColors.profit
                      : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Products List Card ───────────────────────────────────────────────
  Widget _buildProductsCard(List<Product> products) {
    final currency = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: products.take(5).length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final p = products[index];
          final health = stockHealth(p.effectiveStockQty);

          return InkWell(
            onTap: () => _applyProductSearch(p),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (p.brand != null && p.brand!.isNotEmpty) ...[
                              Text(
                                p.brand!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              const Text(' • ',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            ],
                            Text(
                              currency.format(p.sellingPrice),
                              style: const TextStyle(
                                color: AppColors.profit,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: health.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: health.color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${p.effectiveStockQty} left',
                      style: TextStyle(
                        color: health.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 11, color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: const Text(
        'AI ASSISTANT',
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle!,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
