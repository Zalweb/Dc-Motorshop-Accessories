import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/router/route_paths.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/primary_button.dart';

/// Screen 2 — Enter the 6-digit OTP that was emailed to the user.
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  /// SHA-256 hex hash — mirrors exactly what the Edge Function stores.
  String _sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _verify() async {
    final otp = _otp;
    if (otp.length != 6) {
      setState(() => _error = 'Please enter all 6 digits');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = SupabaseService.client;

      // Fetch the latest unused OTP row for this email
      final rows = await supabase
          .from('password_resets')
          .select()
          .eq('email', widget.email)
          .eq('used', false)
          .order('created_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) {
        throw Exception('No reset code found. Please request a new one.');
      }

      final row = rows.first;
      final expiresAt = DateTime.parse(row['expires_at'] as String);

      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('Code has expired. Please request a new one.');
      }

      // Compare SHA-256 of typed OTP with stored hash
      final inputHash = _sha256Hex(otp);
      if (inputHash != (row['otp_hash'] as String)) {
        throw Exception('Incorrect code. Please try again.');
      }

      if (!mounted) return;
      // Navigate to reset password, passing email and otp
      context.push(RoutePaths.resetPassword, extra: {'email': widget.email, 'otp': otp});
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final res = await http.post(
        Uri.parse('$kSupabaseUrl/functions/v1/send-otp'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': kSupabaseAnonKey,
        },
        body: jsonEncode({'email': widget.email}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200 || body['error'] != null) {
        throw Exception(body['error'] ?? 'Failed to resend');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('A new code has been sent to your email!')),
        );
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes.first.requestFocus();
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Enter Code'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.mark_email_read_rounded,
                    size: 32, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 20),

              Text('Check your email', style: AppTextStyles.headingMedium),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    // 6 digit boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (i) => _DigitBox(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          onChanged: (val) {
                            if (val.length == 1 && i < 5) {
                              _focusNodes[i + 1].requestFocus();
                            }
                            setState(() => _error = null);
                          },
                          onBackspace: () {
                            if (_controllers[i].text.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                              _controllers[i - 1].clear();
                            }
                          },
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Verify Code',
                      isLoading: _loading,
                      onPressed: _verify,
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: _resending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : GestureDetector(
                              onTap: _resendCode,
                              child: Text(
                                "Didn't receive it? Resend code",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single digit input box for the OTP pin pad.
class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 44,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
