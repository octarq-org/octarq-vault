import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/e2ee_sync_service.dart';
import 'auth_provider.dart';

/// Pending sync conflicts (same asset id + same `updatedAt`, different content).
/// Cleared when the vault locks or the user resolves each item.
class PendingSyncConflictsNotifier extends Notifier<List<AssetConflict>> {
  @override
  List<AssetConflict> build() {
    ref.listen(authProvider, (_, next) {
      if (next == AuthState.locked || next == AuthState.unsetup) {
        state = [];
      }
    });
    return [];
  }

  void mergeFrom(List<AssetConflict> incoming) {
    if (incoming.isEmpty) return;
    final byId = <String, AssetConflict>{for (final c in state) c.local.id: c};
    for (final c in incoming) {
      byId[c.local.id] = c;
    }
    state = byId.values.toList();
  }

  void removeForAsset(String assetId) {
    state = state.where((c) => c.local.id != assetId).toList();
  }

  void clear() => state = [];
}

final pendingSyncConflictsProvider =
    NotifierProvider<PendingSyncConflictsNotifier, List<AssetConflict>>(() {
      return PendingSyncConflictsNotifier();
    });
