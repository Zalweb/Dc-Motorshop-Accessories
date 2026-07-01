import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: unused_import — UserAttributes is used (re-exported via supabase_service)
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
// ignore: unused_import — SupabaseService.client is used in _submit
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/primary_button.dart';

/// Screen 3 — Set a new password after OTP verification.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);

      // 1. Update password in local Isar database (silently skips if not found locally)
      await authRepo.changePasswordByEmail(
        email: widget.email,
        newPassword: _newPass.text,
      );

      // 2. Securely call the Edge Function to reset password in Supabase Auth
      final res = await SupabaseService.client.functions.invoke(
        'reset-password',
        body: {
          'email': widget.email,
          'new_password': _newPass.text,
          'otp': widget.otp,
        },
      );

      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }

      setState(() => _success = true);
    } catch (e) {
      setState(
          () => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_success) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 48),
                  ),
                  const SizedBox(height: 24),
                  Text('Password Updated!',
                      style: AppTextStyles.headingMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Your password has been changed successfully. Please sign in with your new password.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Back to Sign In',
                    onPressed: () => context.go(RoutePaths.login),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('New Password'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.lock_open_rounded,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),

                Text('Create new password', style: AppTextStyles.headingMedium),
                const SizedBox(height: 8),
                Text(
                  'Your new password must be at least 8 characters long.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // New password
                      _PasswordField(
                        label: 'New Password',
                        hint: 'At least 8 characters',
                        controller: _newPass,
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirm password
                      _PasswordField(
                        label: 'Confirm Password',
                        hint: 'Re-enter your new password',
                        controller: _confirmPass,
                        obscure: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v != _newPass.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
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
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      PrimaryButton(
                        label: 'Update Password',
                        isLoading: _loading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w700)),
            const Text(' *',
                style: TextStyle(color: AppColors.danger)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(obscure ? 'Show' : 'Hide'),
            ),
          ),
        ),
      ],
    );
  }
}
