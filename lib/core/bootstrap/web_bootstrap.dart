import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';

/// Web boot: no local Isar database. Only SharedPreferences is overridden;
/// the cloud-only data layer reads/writes Supabase directly.
Future<void> runWithOverrides(Widget child) async {
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: child,
    ),
  );
}
