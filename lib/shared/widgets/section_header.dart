import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

/// Uppercase muted section label (e.g. "AT A GLANCE", "PRICING", "INVENTORY").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label.toUpperCase(), style: AppTextStyles.labelCaps),
    );
  }
}
