import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'voice_intent_parser.dart';

final voiceAssistantServiceProvider = Provider<VoiceAssistantService>((ref) {
  final service = VoiceAssistantService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

class VoiceAssistantService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isSpeechInitialized = false;
  bool _isTtsInitialized = false;

  /// Reactive notifier for TTS speaking status
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);

  /// Reactive notifier for speech listening status
  final ValueNotifier<bool> isListeningNotifier = ValueNotifier<bool>(false);

  bool get isListening => isListeningNotifier.value || _speech.isListening;
  bool get isSpeaking => isSpeakingNotifier.value;
  bool get isAvailable => _isSpeechInitialized;

  Future<bool> initialize() async {
    if (_isSpeechInitialized) return true;

    try {
      _isSpeechInitialized = await _speech.initialize(
        onError: (val) {
          isListeningNotifier.value = false;
          debugPrint('VoiceAssistant STT Error: ${val.errorMsg}');
        },
        onStatus: (val) {
          final listening = val == 'listening';
          if (isListeningNotifier.value != listening) {
            isListeningNotifier.value = listening;
          }
          debugPrint('VoiceAssistant STT Status: $val');
        },
        debugLogging: kDebugMode,
      );

      // Initialize TTS
      await _initTts();

      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('VoiceAssistant init failed: $e');
      isListeningNotifier.value = false;
      _isSpeechInitialized = false;
      return false;
    }
  }

  Future<void> _initTts() async {
    if (_isTtsInitialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // On iOS, wait for completion
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambientSolo,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          ],
        );
      }

      _tts.setStartHandler(() {
        isSpeakingNotifier.value = true;
      });
      _tts.setCompletionHandler(() {
        isSpeakingNotifier.value = false;
      });
      _tts.setErrorHandler((_) {
        isSpeakingNotifier.value = false;
      });
      _tts.setCancelHandler(() {
        isSpeakingNotifier.value = false;
      });

      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('VoiceAssistant TTS init error: $e');
    }
  }

  /// Starts listening for voice input.
  /// [onResult] is called with recognized text and whether it's final.
  Future<bool> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(String error)? onError,
    ListenMode listenMode = ListenMode.search,
  }) async {
    final available = await initialize();
    if (!available) {
      isListeningNotifier.value = false;
      onError?.call('Microphone or Speech Recognition not available');
      return false;
    }

    // Stop speaking if currently speaking
    await stopSpeaking();

    try {
      isListeningNotifier.value = true;
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            isListeningNotifier.value = false;
          }
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: SpeechListenOptions(
          listenMode: listenMode,
          cancelOnError: true,
          partialResults: true,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 20),
        ),
      );
      return true;
    } catch (e) {
      isListeningNotifier.value = false;
      debugPrint('VoiceAssistant listen error: $e');
      onError?.call(e.toString());
      return false;
    }
  }

  /// Stops speech listening.
  Future<void> stopListening() async {
    isListeningNotifier.value = false;
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// Cancels listening immediately.
  Future<void> cancelListening() async {
    isListeningNotifier.value = false;
    await _speech.cancel();
  }

  /// Formats response into clean speech text by stripping emoji and markdown.
  static String cleanTextForSpeech(String text) {
    var cleaned = text;
    // Strip emojis
    cleaned = cleaned.replaceAll(
      RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true),
      '',
    );
    // Replace ₱ with pesos
    cleaned = cleaned.replaceAll('₱', 'pesos ');
    // Remove bullets and leading markers
    cleaned = cleaned.replaceAll('•', ' ');
    cleaned = cleaned.replaceAll(RegExp(r'^[•\-\*]\s*', multiLine: true), '');
    // Clean markdown formatting
    cleaned = cleaned.replaceAll(RegExp(r'[\*_]{1,2}'), '');
    // Clean pipe separators
    cleaned = cleaned.replaceAll('|', ', ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  /// Speaks [message] aloud using on-device text-to-speech.
  Future<void> speak(String message) async {
    if (!_isTtsInitialized) {
      await _initTts();
    }
    final speechText = cleanTextForSpeech(message);
    if (speechText.isEmpty) return;

    try {
      await _tts.stop();
      isSpeakingNotifier.value = true;
      await _tts.speak(speechText);
    } catch (e) {
      isSpeakingNotifier.value = false;
      debugPrint('VoiceAssistant speak error: $e');
    }
  }

  /// Stops any ongoing speech.
  Future<void> stopSpeaking() async {
    isSpeakingNotifier.value = false;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Parses text into a structured VoiceIntent.
  VoiceIntent parseIntent(String speechText) {
    return VoiceIntentParser.parse(speechText);
  }

  void dispose() {
    try {
      _speech.stop().catchError((_) {});
    } catch (_) {}
    try {
      _tts.stop().catchError((_) {});
    } catch (_) {}
    isSpeakingNotifier.dispose();
    isListeningNotifier.dispose();
  }
}
