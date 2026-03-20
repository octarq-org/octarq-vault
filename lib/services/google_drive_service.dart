import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;
import 'package:http/http.dart' as http;

import 'e2ee_sync_service.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService(ref.read(e2eeSyncServiceProvider));
});

class GoogleDriveService {
  static const String _backupFileName = 'octarq_vault.enc';

  final E2EESyncService _syncService;

  final List<String> _scopes = [drive.DriveApi.driveAppdataScope];

  GoogleDriveService(this._syncService);

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      // In a real app we might pass clientId here, but on Web it's usually in index.html
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
        print(
          'attemptLightweightAuthentication is unimplemented. Falling back to authenticate.',
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
        if (kDebugMode) print('authenticate unimplemented error.');
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) print('Google Sign-In failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    await _ensureInitialized();
    try {
      // Ensure user is authenticated and has granted Drive scope.
      GoogleSignInAccount? account;
      try {
        account = await GoogleSignIn.instance.attemptLightweightAuthentication(
          reportAllExceptions: false,
        );
      } catch (_) {}
      account ??= await GoogleSignIn.instance.authenticate(scopeHint: _scopes);

      // Authorize Drive-specific scopes and obtain an access token.
      final tokenData = await account.authorizationClient.authorizeScopes(
        _scopes,
      );
      final accessToken = tokenData.accessToken;
      if (accessToken.isEmpty) {
        throw Exception('Empty access token returned from Google Sign-In.');
      }

      // Build a non-refreshing auth client (valid ~1 h). For long-running
      // sessions the user may need to re-authenticate.
      final credentials = gauth.AccessCredentials(
        gauth.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null, // no refresh token available via google_sign_in
        _scopes,
      );
      final authClient = gauth.authenticatedClient(http.Client(), credentials);
      return drive.DriveApi(authClient);
    } catch (e) {
      if (kDebugMode) print('Drive API auth error: $e');
      return null;
    }
  }

  /// Locate the backup file in appDataFolder
  Future<String?> _getFileId(drive.DriveApi api) async {
    final fileList = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
      $fields: 'files(id, name)',
    );
    final files = fileList.files;
    if (files != null && files.isNotEmpty) {
      return files.first.id;
    }
    return null;
  }

  /// Sync currently loaded assets into E2EE payload and upload to Google Drive
  Future<void> syncToDrive(
    List<Asset> assets, {
    List<AssetType> customAssetTypes = const [],
    List<Map<String, dynamic>> relations = const [],
    List<Map<String, dynamic>> tombstones = const [],
  }) async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Not signed in to Google Drive');

    final encryptedBlob = _syncService.packSnapshotTOCiphertext(
      assets,
      customAssetTypes: customAssetTypes,
      relations: relations,
      tombstones: tombstones,
    );

    final media = drive.Media(
      Stream.value(encryptedBlob.toList()),
      encryptedBlob.length,
    );

    final fileId = await _getFileId(api);
    if (fileId == null) {
      // Create new file
      final file = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder'];
      await api.files.create(file, uploadMedia: media);
    } else {
      // Update existing
      final file = drive.File()..name = _backupFileName;
      await api.files.update(file, fileId, uploadMedia: media);
    }

    if (kDebugMode) {
      print('Successfully pushed E2EE snapshot to Google Drive appDataFolder.');
    }
  }

  /// Download the E2EE payload from Google Drive as raw bytes for Cold Start recovery.
  Future<Uint8List?> readRawBytesFromDrive() async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Not signed in to Google Drive');

    final fileId = await _getFileId(api);
    if (fileId == null) return null; // No backup yet

    // Bypass strict type casting `as drive.Media` which crashes on Web (minified JS)
    final dynamic response = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    final List<int> bytes = [];
    await for (var chunk in (response.stream as Stream)) {
      if (chunk is List<int>) {
        bytes.addAll(chunk);
      } else if (chunk is Iterable) {
        bytes.addAll(chunk.map((dynamic e) => e as int));
      } else {
        // Fallback for JS web types or strings if returned unexpectedly
        try {
          final dynChunk = chunk as dynamic;
          bytes.addAll(List<int>.from(dynChunk));
        } catch (_) {
          // If even that fails, we ignore or log.
          if (kDebugMode) {
            print('Unrecognized chunk type: ${chunk.runtimeType}');
          }
        }
      }
    }

    final uint8List = Uint8List.fromList(bytes);
    if (uint8List.isEmpty) return null;
    return uint8List;
  }

  /// Download the E2EE payload from Google Drive and unpack it into a VaultSnapshot
  Future<VaultSnapshot?> readFromDrive() async {
    final uint8List = await readRawBytesFromDrive();
    if (uint8List == null) return null;
    return _syncService.unpackCiphertextToSnapshot(uint8List);
  }
}
