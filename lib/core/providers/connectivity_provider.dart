import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams the live connectivity state as a simple [bool].
/// `true`  = at least one interface is up (WiFi, mobile, ethernet…)
/// `false` = no connection at all.
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));
});
