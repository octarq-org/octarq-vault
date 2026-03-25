import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attachment.dart';
import 'assets_provider.dart';
import 'service_providers.dart';

/// Returns all [AssetAttachment] records for [assetId].
///
/// On web, reads from [AssetsNotifier]'s in-memory manifest (IndexedDB blobs).
/// On native, ensures the database is open before querying.
final attachmentsProvider =
    FutureProvider.family<List<AssetAttachment>, String>((ref, assetId) async {
      if (kIsWeb) {
        return ref.read(assetsProvider.notifier).webAttachmentsFor(assetId);
      }

      final dbSvc = ref.read(databaseServiceProvider);
      if (!dbSvc.isOpen) {
        final key = ref.read(encryptionServiceProvider).masterKey;
        await dbSvc.ensureOpen(key);
      }
      return dbSvc.getAttachmentsForAsset(assetId);
    });
