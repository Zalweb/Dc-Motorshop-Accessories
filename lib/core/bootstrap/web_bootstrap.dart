import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';
import '../web/web_session.dart';

/// Web boot: no local Isar database. Only SharedPreferences is overridden;
/// the cloud-only data layer reads/writes Supabase directly.
Future<void> runWithOverrides(Widget child) async {
  final prefs = await SharedPreferences.getInstance();
  final cachedBizId = prefs.getString('web_cached_business_id');
  if (cachedBizId != null && cachedBizId.isNotEmpty) {
    WebSession.businessId = cachedBizId;
  }
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: child,
    ),
  );
}
