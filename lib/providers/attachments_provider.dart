import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attachment.dart';
import 'service_providers.dart';

/// Returns all [AssetAttachment] records for [assetId].
///
/// On web, attachments are not supported — returns an empty list immediately.
/// On native, ensures the database is open before querying.
final attachmentsProvider =
    FutureProvider.family<List<AssetAttachment>, String>((ref, assetId) async {
      if (kIsWeb) return [];

      final dbSvc = ref.read(databaseServiceProvider);
      if (!dbSvc.isOpen) {
        final key = ref.read(encryptionServiceProvider).masterKey;
        await dbSvc.ensureOpen(key);
      }
      return dbSvc.getAttachmentsForAsset(assetId);
    });
