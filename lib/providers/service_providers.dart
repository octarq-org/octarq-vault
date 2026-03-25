import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/attachment_service.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';
import '../services/secure_storage_service.dart';
import '../services/notification_service.dart';
import '../services/web_vault_storage.dart';
import '../services/icloud_sync_service.dart';

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => DatabaseService(),
);
final encryptionServiceProvider = Provider<EncryptionService>(
  (ref) => EncryptionService(),
);
final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);
final webVaultStorageProvider = Provider<WebVaultStorage>(
  (ref) => WebVaultStorage(),
);
final iCloudSyncServiceProvider = Provider<ICloudSyncService>(
  (ref) => ICloudSyncService(),
);
final attachmentServiceProvider = Provider<AttachmentService>(
  (ref) => AttachmentService(ref.read(encryptionServiceProvider)),
);
