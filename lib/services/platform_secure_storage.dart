import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Darwin: plugin defaults to data-protection keychain on macOS (`?? true` in
/// native code), which needs `keychain-access-groups` and a dev cert — without
/// that you get -34018 at runtime. Legacy keychain is enough for this app.
FlutterSecureStorage platformFlutterSecureStorage() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    return const FlutterSecureStorage(
      mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    );
  }
  return const FlutterSecureStorage();
}
