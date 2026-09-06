import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/bootstrap.dart' as boot;
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_service.dart';
import 'core/sync/connectivity_sync.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/motion_controller.dart';
import 'core/theme/page_transitions.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/theme/theme_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase before anything else — this sets up the auth client
  // and restores any persisted session automatically (secure storage on
  // native, shared_preferences on web via supabase_flutter).
  await SupabaseService.initialize();

  // Platform-specific boot: native opens Isar; web is cloud-only (no Isar).
  await boot.runWithOverrides(const DcMotorcycleInventoryApp());
}

class DcMotorcycleInventoryApp extends ConsumerWidget {
  const DcMotorcycleInventoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keep the connectivity-triggered sync subscription alive for the app's lifetime.
    ref.watch(connectivitySyncProvider);
    final settingsVal = ref.watch(businessSettingsStreamProvider);

    final settings = settingsVal.value;
    final themeColorName = settings?.themeColor ?? 'Blue';

    final colorOption = kThemeOptions.firstWhere(
      (o) => o.name.toLowerCase() == themeColorName.toLowerCase(),
      orElse: () => kThemeOptions.firstWhere((o) => o.name == 'Blue'),
    );

    final motionEnabled = ref.watch(motionEnabledProvider);

    final pageTransitions =
        motionEnabled ? kMotionPageTransitionsTheme : kNoMotionPageTransitionsTheme;
    final lightTheme = AppTheme.lightTheme(colorOption.color)
        .copyWith(pageTransitionsTheme: pageTransitions);
    final darkTheme = AppTheme.darkTheme(colorOption.color)
        .copyWith(pageTransitionsTheme: pageTransitions);

    return MaterialApp.router(
      title: 'DC Motorcycle Inventory',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: !motionEnabled),
        child: child!,
      ),
    );
  }
}
