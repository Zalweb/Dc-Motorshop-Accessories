import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/services/chatbot/chatbot_engine.dart';
import '../../core/services/chatbot/chatbot_models.dart';
import '../../core/services/voice/voice_assistant_service.dart';
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
  /// or a modal bottom sheet on Mobile.
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
        isScrollControlled: true,
        backgroundColor: AppColors.bgSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.88,
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

class _ChatbotModalState extends ConsumerState<ChatbotModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _autoSpeak = false;
  String _listeningTranscript = '';
  String? _currentlySpeakingMessageId;

  final List<String> _quickActionChips = [
    '💰 Today\'s Sales',
    '📈 Today\'s Profit',
    '⚠️ Low Stock Alert',
    '🧮 10% off 1500',
    '💵 Sukli 1000 - 680',
    '📦 Motul oil stock',
    '💸 Today\'s Expenses',
    '💡 Quick Help',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.28).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial greeting message
    _messages.add(
      ChatMessage(
        id: 'welcome',
        text:
            'Hello! I am your DC Motorshop AI Chatbot. '
            'I can calculate discounts and change, check parts stock, alert you on low inventory, '
            'and summarize today\'s sales and profit.\n\nHow can I help you right now?',
        isUser: false,
        timestamp: DateTime.now(),
        intentType: ChatbotIntentType.greeting,
        actionChips: [
          '💰 Today\'s Sales',
          '⚠️ Low Stock Alert',
          '🧮 10% off 1500',
          '📦 Check Product Stock',
        ],
      ),
    );

    final voiceService = ref.read(voiceAssistantServiceProvider);
    voiceService.isSpeakingNotifier.addListener(_onSpeakingChanged);

    // If an initial query was passed, run it
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSendMessage(widget.initialQuery!);
      });
    }
  }

  void _onSpeakingChanged() {
    if (mounted) {
      final isSpeaking = ref.read(voiceAssistantServiceProvider).isSpeaking;
      if (!isSpeaking && _currentlySpeakingMessageId != null) {
        setState(() {
          _currentlySpeakingMessageId = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    ref.read(voiceAssistantServiceProvider).isSpeakingNotifier.removeListener(_onSpeakingChanged);
    ref.read(voiceAssistantServiceProvider).stopListening();
    ref.read(voiceAssistantServiceProvider).stopSpeaking();
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

    if (_autoSpeak) {
      _speakMessage(botResponse);
    }
  }

  Future<void> _startVoiceListening() async {
    final service = ref.read(voiceAssistantServiceProvider);
    setState(() {
      _isListening = true;
      _listeningTranscript = '';
    });

    final success = await service.startListening(
      onResult: (text, isFinal) {
        setState(() {
          _listeningTranscript = text;
          _inputController.text = text;
        });

        if (isFinal && text.trim().isNotEmpty) {
          _stopVoiceListening(shouldSubmit: true);
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice recognition: $error'),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );

    if (!success && mounted) {
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone not available or permission denied.'),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _stopVoiceListening({bool shouldSubmit = false}) async {
    if (!_isListening) return;
    final text = _listeningTranscript.trim();
    setState(() {
      _isListening = false;
      _listeningTranscript = '';
    });
    final service = ref.read(voiceAssistantServiceProvider);
    await service.stopListening();

    if (shouldSubmit && text.isNotEmpty) {
      _handleSendMessage(text);
    }
  }

  void _speakMessage(ChatMessage message) async {
    final service = ref.read(voiceAssistantServiceProvider);
    if (_currentlySpeakingMessageId == message.id) {
      await service.stopSpeaking();
      setState(() => _currentlySpeakingMessageId = null);
      return;
    }

    setState(() => _currentlySpeakingMessageId = message.id);
    await service.speak(message.text);
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
    // Keep streams active while modal is mounted
    ref.watch(productListStreamProvider);
    ref.watch(saleListStreamProvider);
    ref.watch(expenseListStreamProvider);

    return SafeArea(
      child: Column(
        children: [
          // Drag handle on mobile
          if (MediaQuery.sizeOf(context).width < 800) ...[
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],

          // ── Chat Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
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
                        'Inventory • Sales • Calculator • Voice',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sound Auto-TTS Toggle
                IconButton(
                  tooltip: _autoSpeak
                      ? 'Auto-Voice: Enabled (Tap to mute)'
                      : 'Auto-Voice: Muted (Tap to speak replies)',
                  icon: Icon(
                    _autoSpeak
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: _autoSpeak ? AppColors.accent : AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _autoSpeak = !_autoSpeak;
                    });
                    if (!_autoSpeak) {
                      ref.read(voiceAssistantServiceProvider).stopSpeaking();
                    }
                  },
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
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // ── Live Speech Listening Indicator ───────────────────────────
          if (_isListening)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _listeningTranscript.isEmpty
                          ? 'Listening... Speak part name or math...'
                          : '"$_listeningTranscript"',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop_rounded,
                        color: AppColors.danger, size: 20),
                    onPressed: () => _stopVoiceListening(shouldSubmit: true),
                    tooltip: 'Finish speaking',
                  ),
                ],
              ),
            ),

          // ── Quick Suggestions Bar ─────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickActionChips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final chip = _quickActionChips[index];
                return InkWell(
                  onTap: () {
                    // Strip emoji for query if necessary or send raw
                    final cleanQuery = chip.replaceAll(
                        RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]',
                            unicode: true),
                        '').trim();
                    _handleSendMessage(cleanQuery);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface2,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      chip,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Input Row (Text + Mic + Send) ──────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 4,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
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
                        color: _isListening
                            ? AppColors.accent
                            : theme.colorScheme.outlineVariant
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

                // Microphone Button
                GestureDetector(
                  onTap: () {
                    if (_isListening) {
                      _stopVoiceListening(shouldSubmit: true);
                    } else {
                      _startVoiceListening();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? AppColors.danger
                                : AppColors.bgSurface2,
                            border: Border.all(
                              color: _isListening
                                  ? AppColors.danger
                                  : AppColors.border,
                            ),
                          ),
                          child: Icon(
                            _isListening
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            color: _isListening
                                ? Colors.white
                                : AppColors.accent,
                            size: 22,
                          ),
                        ),
                      );
                    },
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
      ),
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
    final isSpeakingThis = _currentlySpeakingMessageId == msg.id;

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
                  // Bot label & speech actions
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
                      Row(
                        children: [
                          // Speaker button
                          InkWell(
                            onTap: () => _speakMessage(msg),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isSpeakingThis
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_up_outlined,
                                size: 16,
                                color: isSpeakingThis
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Copy text button
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
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Main Text
                  Text(
                    msg.text,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),

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
            if (msg.actionChips.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: msg.actionChips.map((chip) {
                  return InkWell(
                    onTap: () {
                      final cleanQuery = chip.replaceAll(
                          RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]',
                              unicode: true),
                          '').trim();
                      _handleSendMessage(cleanQuery);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        chip,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
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
