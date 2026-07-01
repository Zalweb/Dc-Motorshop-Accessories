import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncState { idle, syncing, success, conflict, error }

class SyncStateNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => SyncState.idle;

  void setSyncing() => state = SyncState.syncing;
  
  void setSuccess() {
    state = SyncState.success;
    Future.delayed(const Duration(seconds: 3), () {
      if (state == SyncState.success) {
        state = SyncState.idle;
      }
    });
  }

  void setConflict() {
    state = SyncState.conflict;
    Future.delayed(const Duration(seconds: 5), () {
      if (state == SyncState.conflict) {
        state = SyncState.idle;
      }
    });
  }

  void setError() {
    state = SyncState.error;
    Future.delayed(const Duration(seconds: 4), () {
      if (state == SyncState.error) {
        state = SyncState.idle;
      }
    });
  }
}

final syncStateProvider = NotifierProvider<SyncStateNotifier, SyncState>(() {
  return SyncStateNotifier();
});
