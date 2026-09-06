import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cloud-only web: connectivity-triggered sync is unnecessary (data lives in
/// Supabase). Kept as a no-op provider so `main()` keeps its subscription.
final connectivitySyncProvider = Provider<void>((ref) {});
