import 'package:flutter/material.dart';

/// Rounded search input used on Products, Sales, and New Sale screens,
/// with support for hardware barcode scanners (Enter / onSubmitted) and focus control.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.onVoicePressed,
  });

  final String hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final VoidCallback? onVoicePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              suffixIcon: onVoicePressed != null
                  ? IconButton(
                      icon: const Icon(Icons.mic_rounded, color: Color(0xFF3B82F6)),
                      tooltip: 'Voice Search & AI Assistant',
                      onPressed: onVoicePressed,
                    )
                  : null,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}
