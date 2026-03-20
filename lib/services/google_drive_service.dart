import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;
import 'package:http/http.dart' as http;

import 'e2ee_sync_service.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';
import '../models/attachment.dart';

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService(ref.read(e2eeSyncServiceProvider));
});

class GoogleDriveService {
  static const String _snapshotFileName = 'octarq_vault.enc';
  static const String _attachmentFolder = 'octarq_attachments';

  final E2EESyncService _syncService;
  final List<String> _scopes = [drive.DriveApi.driveAppdataScope];

  GoogleDriveService(this._syncService);

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize();
      _initialized = true;
    }
  }

  Future<GoogleSignInAccount?> get currentUser async {
    await _ensureInitialized();
    try {
      return await GoogleSignIn.instance.attemptLightweightAuthentication(
        reportAllExceptions: true,
      );
    } on UnimplementedError {
      if (kDebugMode) {
        debugPrint(
          'attemptLightweightAuthentication is unimplemented. '
          'Falling back to authenticate.',
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasCredentials() async {
    try {
      final account = await currentUser;
      return account != null;
    } catch (_) {
      return false;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      await _ensureInitialized();
      try {
        return await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
      } on UnimplementedError {
        if (kDebugMode) debugPrint('authenticate unimplemented error.');
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Google Sign-In failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
  }

  // -------------------------------------------------------------------------
  // Drive API client
  // -------------------------------------------------------------------------

  Future<drive.DriveApi?> _getDriveApi() async {
    await _ensureInitialized();
    try {
      GoogleSignInAccount? account;
      try {
        account = await GoogleSignIn.instance.attemptLightweightAuthentication(
          reportAllExceptions: false,
        );
      } catch (_) {}
      account ??= await GoogleSignIn.instance.authenticate(scopeHint: _scopes);

      final tokenData = await account.authorizationClient.authorizeScopes(
        _scopes,
      );
      final accessToken = tokenData.accessToken;
      if (accessToken.isEmpty) {
        throw Exception('Empty access token returned from Google Sign-In.');
      }

      final credentials = gauth.AccessCredentials(
        gauth.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        _scopes,
      );
      final authClient = gauth.authenticatedClient(http.Client(), credentials);
      return drive.DriveApi(authClient);
    } catch (e) {
      if (kDebugMode) print('Drive API auth error: $e');
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // File helpers
  // -------------------------------------------------------------------------

  Future<String?> _getFileId(
    drive.DriveApi api,
    String fileName,
  ) async {
    final fileList = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$fileName'",
      $fields: 'files(id, name)',
    );
    final files = fileList.files;
    return (files != null && files.isNotEmpty) ? files.first.id : null;
  }

  Future<Uint8List?> _downloadFile(drive.DriveApi api, String fileId) async {
    final dynamic response = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    final List<int> bytes = [];
    await for (final chunk in (response.stream as Stream)) {
      if (chunk is List<int>) {
        bytes.addAll(chunk);
      } else if (chunk is Iterable) {
        bytes.addAll(chunk.map((dynamic e) => e as int));
      } else {
        try {
          bytes.addAll(List<int>.from(chunk as dynamic));
        } catch (_) {
          if (kDebugMode) {
            debugPrint('Unrecognised chunk type: ${chunk.runtimeType}');
          }
        }
      }
    }
    final result = Uint8List.fromList(bytes);
    return result.isEmpty ? null : result;
  }

  Future<void> _uploadFile(
    drive.DriveApi api,
    String fileName,
    Uint8List data,
  ) async {
    final media = drive.Media(
      Stream.value(data.toList()),
      data.length,
    );
    final existingId = await _getFileId(api, fileName);
    if (existingId == null) {
      final file = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder'];
      await api.files.create(file, uploadMedia: media);
    } else {
      final file = drive.File()..name = fileName;
      await api.files.update(file, existingId, uploadMedia: media);
    }
  }

  // -------------------------------------------------------------------------
  // Full snapshot sync
  // -------------------------------------------------------------------------

  /// Encrypts the vault state and uploads it to Drive as [_snapshotFileName].
  Future<void> syncToDrive(
    List<Asset> assets, {
    List<AssetType> customAssetTypes = const [],
    List<Map<String, dynamic>> relations = const [],
    List<Map<String, dynamic>> tombstones = const [],
    List<OpLogEntry> opLog = const [],
    List<AssetAttachment> attachmentManifest = const [],
  }) async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Not signed in to Google Drive');

    final blob = _syncService.packSnapshotTOCiphertext(
      assets,
      customAssetTypes: customAssetTypes,
      relations: relations,
      tombstones: tombstones,
      opLog: opLog,
      attachmentManifest: attachmentManifest,
    );
    await _uploadFile(api, _snapshotFileName, blob);

    if (kDebugMode) {
      debugPrint('Pushed full E2EE snapshot to Google Drive appDataFolder.');
    }
  }

  /// Downloads and decrypts the vault snapshot from Drive.
  Future<VaultSnapshot?> readFromDrive() async {
    final bytes = await readRawBytesFromDrive();
    if (bytes == null) return null;
    return _syncService.unpackCiphertextToSnapshot(bytes);
  }

  /// Downloads the raw encrypted snapshot bytes from Drive.
  Future<Uint8List?> readRawBytesFromDrive() async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Not signed in to Google Drive');

    final fileId = await _getFileId(api, _snapshotFileName);
    if (fileId == null) return null;
    return _downloadFile(api, fileId);
  }

  // -------------------------------------------------------------------------
  // Delta sync
  // -------------------------------------------------------------------------

  /// Encrypts [opLogEntries] into a delta blob and uploads it to Drive.
  ///
  /// Delta blobs are stored as `octarq_delta_<maxSeq>.enc` in appDataFolder.
  /// The receiver downloads all delta files with seq > their lastSyncSeq.
  Future<void> syncDeltaToDrive({
    required List<OpLogEntry> opLogEntries,
    required int baseSeq,
    List<AssetAttachment> attachmentManifest = const [],
  }) async {
    if (opLogEntries.isEmpty) return;
    final api = await _getDriveApi();
    if (api == null) throw Exception('Not signed in to Google Drive');

    final maxSeq = opLogEntries.last.seq;
    final fileName = 'octarq_delta_$maxSeq.enc';
    final blob = _syncService.packDeltaToCiphertext(
      opLogEntries: opLogEntries,
      baseSeq: baseSeq,
      attachmentManifest: attachmentManifest,
    );
    await _uploadFile(api, fileName, blob);

    if (kDebugMode) {
      debugPrint(
        'Pushed delta (${opLogEntries.length} entries, seq $baseSeq→$maxSeq) '
        'to Google Drive.',
      );
    }
  }

  /// Lists all delta blob file names in appDataFolder.
  Future<List<String>> listDeltaFiles() async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Not signed in to Google Drive');

    final fileList = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains 'octarq_delta_'",
      $fields: 'files(id, name)',
    );
    return (fileList.files ?? [])
        .map((f) => f.name ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
  }

  // -------------------------------------------------------------------------
  // Attachment sync
  // -------------------------------------------------------------------------

  /// Uploads the encrypted blob for [attachment] to Drive.
  ///
  /// The blob is stored at `octarq_attachments/<uuid>.enc` in appDataFolder.
  Future<void> uploadAttachment(
    AssetAttachment attachment,
    Uint8List encBytes,
  ) async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Not signed in to Google Drive');

    final fileName = '$_attachmentFolder/${attachment.encFileName}';
    await _uploadFile(api, fileName, encBytes);

    if (kDebugMode) {
      debugPrint('Uploaded attachment ${attachment.encFileName} to Drive.');
    }
  }

  /// Downloads the raw encrypted blob for [attachment] from Drive.
  ///
  /// Returns `null` if the file does not exist on Drive yet.
  Future<Uint8List?> downloadAttachment(AssetAttachment attachment) async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Not signed in to Google Drive');

    final fileName = '$_attachmentFolder/${attachment.encFileName}';
    final fileId = await _getFileId(api, fileName);
    if (fileId == null) return null;
    return _downloadFile(api, fileId);
  }

  /// Deletes the remote attachment blob from Drive.
  Future<void> deleteRemoteAttachment(AssetAttachment attachment) async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Not signed in to Google Drive');

    final fileName = '$_attachmentFolder/${attachment.encFileName}';
    final fileId = await _getFileId(api, fileName);
    if (fileId != null) await api.files.delete(fileId);
  }
}
