/// An in-memory registry of asset tombstones (soft-deletion records).
///
/// A tombstone maps an asset ID to the millisecond-epoch timestamp at which
/// it was deleted. During LWW sync merges, an asset is omitted when its
/// tombstone's [deletedAt] is strictly greater than the asset's [updatedAt].
class TombstoneRegistry {
  final Map<String, int> _tombstones = {};

  /// Records a tombstone for [id] at [deletedAt].
  ///
  /// Only updates the stored value when [deletedAt] is strictly greater than
  /// the previously stored timestamp, so stale tombstones never overwrite
  /// fresher ones.
  void record(String id, int deletedAt) {
    final existing = _tombstones[id];
    if (existing == null || deletedAt > existing) {
      _tombstones[id] = deletedAt;
    }
  }

  /// Bulk-loads tombstones from the snapshot list format
  /// `[{id: String, deletedAt: int}, ...]`.
  ///
  /// Each entry is applied via [record], so the newer-wins rule holds even
  /// when merging with already-recorded tombstones.
  void loadFromList(List<Map<String, dynamic>> tombstones) {
    for (final t in tombstones) {
      final id = t['id'] as String?;
      final deletedAt = t['deletedAt'] as int?;
      if (id != null && deletedAt != null) {
        record(id, deletedAt);
      }
    }
  }

  /// Returns `true` when [id] has a tombstone whose [deletedAt] is strictly
  /// greater than [assetUpdatedAt], meaning the deletion should win.
  bool shouldDelete(String id, int assetUpdatedAt) {
    final deletedAt = _tombstones[id];
    return deletedAt != null && deletedAt > assetUpdatedAt;
  }

  /// Returns `true` if any tombstone has been recorded for [id].
  bool contains(String id) => _tombstones.containsKey(id);

  /// Converts the registry to the snapshot list format for serialization.
  List<Map<String, dynamic>> toList() => _tombstones.entries
      .map((e) => {'id': e.key, 'deletedAt': e.value})
      .toList();

  /// The number of tombstones currently held.
  int get length => _tombstones.length;

  bool get isEmpty => _tombstones.isEmpty;
}
