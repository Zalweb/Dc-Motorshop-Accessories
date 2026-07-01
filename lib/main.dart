import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/db/isar_service.dart';
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
  // and restores any persisted session from secure storage automatically.
  await SupabaseService.initialize();

  final isarService = await IsarService.open();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        isarServiceProvider.overrideWithValue(isarService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DcMotorcycleInventoryApp(),
    ),
  );
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

    // Motion on → animated slide+fade page transitions app-wide; off → instant.
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
      // Honors "Motion off" for animations that respect the accessibility flag.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: !motionEnabled),
        child: child!,
      ),
    );
  }
}

