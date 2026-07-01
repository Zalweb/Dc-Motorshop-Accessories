import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../providers.dart';
import '../supabase/supabase_providers.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../data/models/expense.dart';

/// Keep-alive provider: triggers a Supabase sync whenever the device
/// regains connectivity OR when local data is modified.
///
/// Watch it once near the app root so the subscription lives for the
/// app's lifetime.
final connectivitySyncProvider = Provider<void>((ref) {
  final syncService = ref.read(supabaseSyncServiceProvider);
  final isar = ref.read(isarProvider);
  
  Timer? debounceTimer;
  
  void scheduleSync() {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(seconds: 3), () async {
      try {
        final results = await Connectivity().checkConnectivity();
        final isOnline = results.any((r) => r != ConnectivityResult.none);
        if (isOnline) {
          await syncService.syncNow();
        }
      } catch (_) {
        // Silently fail on background sync errors
      }
    });
  }

  // Trigger on connectivity restored
  final subConn = Connectivity().onConnectivityChanged.listen((results) {
    if (results.any((r) => r != ConnectivityResult.none)) {
      scheduleSync();
    }
  });
  
  // Trigger on local data mutations (debounced to avoid spamming)
  final subCat = isar.categorys.watchLazy().listen((_) => scheduleSync());
  final subProd = isar.products.watchLazy().listen((_) => scheduleSync());
  final subSale = isar.sales.watchLazy().listen((_) => scheduleSync());
  final subExp = isar.expenses.watchLazy().listen((_) => scheduleSync());

  ref.onDispose(() {
    debounceTimer?.cancel();
    subConn.cancel();
    subCat.cancel();
    subProd.cancel();
    subSale.cancel();
    subExp.cancel();
  });
});
