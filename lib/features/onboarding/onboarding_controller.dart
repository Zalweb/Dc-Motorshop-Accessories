import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../auth/auth_controller.dart';

/// Mutable draft collected across the onboarding steps and persisted once the
/// user reaches the final "You're all set" screen.
///
/// Flow: 1) set up shop (logo + theme) → 2) review categories → 3) invite team.
/// Workflow stages keep their defaults and are edited later from settings.
class OnboardingDraft {
  OnboardingDraft({
    required this.categories,
    required this.themeColor,
    this.logoPath,
  });

  factory OnboardingDraft.initial() => OnboardingDraft(
        categories: ['Parts', 'Services'],
        themeColor: 'Blue',
      );

  List<String> categories;
  String themeColor;
  String? logoPath;

  OnboardingDraft copyWith({
    List<String>? categories,
    String? themeColor,
    String? logoPath,
  }) =>
      OnboardingDraft(
        categories: categories ?? this.categories,
        themeColor: themeColor ?? this.themeColor,
        logoPath: logoPath ?? this.logoPath,
      );
}

class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => OnboardingDraft.initial();

  void setThemeColor(String name) => state = state.copyWith(themeColor: name);

  void setLogoPath(String path) => state = state.copyWith(logoPath: path);

  void addCategory(String name) {
    final value = name.trim();
    if (value.isEmpty || state.categories.contains(value)) return;
    state = state.copyWith(categories: [...state.categories, value]);
  }

  void removeCategory(String name) => state = state.copyWith(
        categories: state.categories.where((c) => c != name).toList(),
      );

  /// Persists the draft and marks the current user's onboarding complete.
  Future<void> finish() async {
    final settings = await ref.read(settingsRepositoryProvider).getOrCreate()
      ..categories = state.categories
      ..themeColor = state.themeColor
      ..logoPath = state.logoPath;
    await ref.read(settingsRepositoryProvider).save(settings);
    await ref.read(categoryRepositoryProvider).seed(state.categories);

    final user = ref.read(authControllerProvider).value;
    if (user != null) {
      await ref.read(authRepositoryProvider).markNewShopSetupComplete(user.id);
      // Refresh auth state so the router guard routes to the dashboard.
      ref.invalidate(authControllerProvider);
    }
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
        OnboardingController.new);
