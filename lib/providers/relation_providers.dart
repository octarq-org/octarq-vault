import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_providers.dart';

Future<void> ensureRelationsDb(Ref ref) async {
  if (kIsWeb) return;
  final dbSvc = ref.read(databaseServiceProvider);
  if (dbSvc.isOpen) return;
  final key = ref.read(encryptionServiceProvider).masterKey;
  await dbSvc.ensureOpen(key);
}

/// Web-only in-memory relation rows (mirrors SQLite `relations` on native).
class WebVaultRelationsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void replace(List<Map<String, dynamic>> next) {
    state = next.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void addRow(Map<String, dynamic> row) {
    state = [...state, Map<String, dynamic>.from(row)];
  }

  void removeById(String id) {
    state = state.where((r) => r['id'] != id).toList();
  }
}

final webVaultRelationsProvider =
    NotifierProvider<WebVaultRelationsNotifier, List<Map<String, dynamic>>>(
      WebVaultRelationsNotifier.new,
    );

final assetRelationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      assetId,
    ) async {
      if (kIsWeb) {
        final rels = ref.watch(webVaultRelationsProvider);
        return rels
            .where(
              (r) =>
                  r['from_asset_id'] == assetId || r['to_asset_id'] == assetId,
            )
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      await ensureRelationsDb(ref);
      final db = ref.read(databaseServiceProvider);
      return await db.getRelationsForAsset(assetId);
    });
