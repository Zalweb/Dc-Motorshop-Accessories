import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/vision/ocr/part_number_ocr_scanner.dart';
import '../../core/services/voice/voice_assistant_service.dart';
import '../../core/theme/app_colors.dart';

/// Rounded search input used across Products, Sales, POS, and Customers screens,
/// with integrated Apple Native iOS Speech (voice queries), Vision Camera OCR
/// (scanning part numbers / labels), hardware barcode scanner support, and focus control.
class SearchField extends ConsumerStatefulWidget {
  const SearchField({
    super.key,
    required this.hint,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.suffix,
    this.enableVoice = true,
    this.enableCameraOcr = true,
  });

  final String hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final Widget? suffix;
  final bool enableVoice;
  final bool enableCameraOcr;

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  TextEditingController? _internalController;
  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      ref.read(voiceAssistantServiceProvider).stopListening();
    }
    _controller.removeListener(_onTextChanged);
    _internalController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleVoiceSearch() async {
    final voiceService = ref.read(voiceAssistantServiceProvider);

    if (_isListening) {
      await voiceService.stopListening();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    setState(() => _isListening = true);

    final started = await voiceService.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
        widget.onChanged?.call(text);
        if (isFinal) {
          setState(() => _isListening = false);
          widget.onSubmitted?.call(text);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mic_off_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(error)),
              ],
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );

    if (!started && mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _scanPartNumberWithCamera() async {
    final scanned = await PartNumberOcrScanner.scan(
      context,
      title: 'Scan Part # with Camera OCR',
      subtitle: 'Point camera at part label or box to search inventory',
    );

    if (scanned != null && mounted) {
      _controller.text = scanned;
      _controller.selection = TextSelection.collapsed(offset: scanned.length);
      widget.onChanged?.call(scanned);
      widget.onSubmitted?.call(scanned);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: _isListening ? 'Listening... Speak now' : widget.hint,
              hintStyle: _isListening
                  ? TextStyle(
                      color: AppColors.accent,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    )
                  : null,
              prefixIcon: _isListening
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              suffixIcon: widget.suffix ?? _buildActionIcons(),
            ),
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 12),
          widget.trailing!,
        ],
      ],
    );
  }

  Widget _buildActionIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_controller.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded, size: 18),
            color: AppColors.textSecondary,
            tooltip: 'Clear search',
            onPressed: () {
              _controller.clear();
              widget.onChanged?.call('');
            },
          ),
        if (widget.enableCameraOcr)
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 20),
            color: AppColors.textSecondary,
            tooltip: 'Scan Part # (Camera OCR)',
            onPressed: _scanPartNumberWithCamera,
          ),
        if (widget.enableVoice)
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              size: 20,
            ),
            color: _isListening ? AppColors.accent : AppColors.textSecondary,
            tooltip: _isListening ? 'Listening... tap to stop' : 'Voice search',
            onPressed: _toggleVoiceSearch,
          ),
      ],
    );
  }
}
