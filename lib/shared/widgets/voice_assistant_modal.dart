import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chatbot_modal.dart';

/// Backward-compatible adapter forwarding to [ChatbotModal].
class VoiceAssistantModal extends ConsumerWidget {
  final ValueChanged<String> onSearchApplied;

  const VoiceAssistantModal({
    super.key,
    required this.onSearchApplied,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onSearchApplied,
  }) {
    return ChatbotModal.show(context, onSearchApplied: onSearchApplied);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChatbotModal(onSearchApplied: onSearchApplied);
  }
}
