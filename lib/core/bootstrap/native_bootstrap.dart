import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/isar_service.dart';
import '../providers.dart';

/// Native boot: opens the local Isar database + SharedPreferences, then runs
/// the app inside a ProviderScope with the Isar-backed overrides.
Future<void> runWithOverrides(Widget child) async {
  final isar = await IsarService.open();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        isarServiceProvider.overrideWithValue(isar),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: child,
    ),
  );
}
