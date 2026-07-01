import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Labeled text field used across the auth and onboarding forms. Shows a
/// "Show" toggle when [onToggleObscure] is provided.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.validator,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.required = false,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
            if (required)
              const Text(' *', style: TextStyle(color: AppColors.danger)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: onToggleObscure == null
                ? null
                : TextButton(
                    onPressed: onToggleObscure,
                    child: Text(obscure ? 'Show' : 'Hide'),
                  ),
          ),
        ),
      ],
    );
  }
}
