import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_options.dart';
import '../auth/auth_controller.dart';
import '../../shared/widgets/glass_container.dart';
import 'onboarding_controller.dart';
import 'widgets/onboarding_scaffold.dart';

/// Step 1 — set up the shop: an optional logo and the accent theme.
class OnboardingSetupShopScreen extends ConsumerWidget {
  const OnboardingSetupShopScreen({super.key});

  Future<void> _pickLogo(WidgetRef ref) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      ref.read(onboardingControllerProvider.notifier).setLogoPath(file.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final draft = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return OnboardingScaffold(
      step: 1,
      stepLabel: 'Shop',
      title: 'Set up your shop',
      subtitle: 'Add a logo and pick an accent. The logo is optional.',
      primaryLabel: 'Continue',
      onPrimary: () => context.push(RoutePaths.onboardingStep2),
      backLabel: 'Log out',
      onBack: () {
        ref.read(authControllerProvider.notifier).logout();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Row: Side-by-side image picker and explanation card
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _pickLogo(ref),
                  child: _LogoPicker(logoPath: draft.logoPath),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUSINESS LOGO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap the avatar box to upload your shop logo. You can skip this and upload it later.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          
          Text('ACCENT COLOR', style: AppTextStyles.labelCaps),
          const SizedBox(height: 14),
          
          // Horizontal scrolling capsule selector instead of a grid
          _ThemeList(
            selected: draft.themeColor,
            onSelected: controller.setThemeColor,
          ),
        ],
      ),
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({required this.logoPath});

  final String? logoPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (logoPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: logoPath!.startsWith('http')
            ? Image.network(logoPath!, width: 90, height: 90, fit: BoxFit.cover)
            : Image.file(File(logoPath!), width: 90, height: 90, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.onSurfaceVariant, size: 24),
          const SizedBox(height: 6),
          Text(
            'Add Logo',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ThemeList extends StatelessWidget {
  const _ThemeList({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kThemeOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final option = kThemeOptions[i];
          final isSelected = option.name == selected;
          
          return GestureDetector(
            onTap: () => onSelected(option.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? option.color.withOpacity(0.12) : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isSelected ? option.color : theme.colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 7, backgroundColor: option.color),
                  const SizedBox(width: 8),
                  Text(
                    option.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? option.color : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

