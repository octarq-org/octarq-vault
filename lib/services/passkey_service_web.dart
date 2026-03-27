import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';

import 'package:flutter/foundation.dart';

class PasskeyService {
  static const _rpName = 'OctarqVault';
  static const _rpId = ''; // Let browser infer current origin RP ID.

  bool get isSupported {
    if (!kIsWeb) return false;
    return _publicKeyCredential != null;
  }

  Future<String?> registerLocalCredential() async {
    if (!isSupported) return null;
    final challenge = _randomBytes(32);
    final userId = _randomBytes(32);
    final options = <String, Object?>{
      'publicKey': <String, Object?>{
        'challenge': challenge,
        if (_rpId.isNotEmpty) 'rp': {'name': _rpName, 'id': _rpId},
        if (_rpId.isEmpty) 'rp': {'name': _rpName},
        'user': {
          'id': userId,
          'name': 'local@octarqvault',
          'displayName': 'OctarqVault Local User',
        },
        'pubKeyCredParams': [
          {'type': 'public-key', 'alg': -7},
          {'type': 'public-key', 'alg': -257},
        ],
        'authenticatorSelection': {
          'residentKey': 'required',
          'userVerification': 'preferred',
        },
        'attestation': 'none',
        'timeout': 60000,
      },
    };

    try {
      final credential = await _credentialsCreate(
        options.jsify() as JSAny,
      ).toDart;
      if (credential == null) return null;
      final idAny = (credential as JSObject).getProperty('id'.toJS);
      return idAny?.dartify() as String?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Passkey register failed: $e');
      }
      return null;
    }
  }

  Future<bool> authenticate() async {
    if (!isSupported) return false;
    final challenge = _randomBytes(32);
    final options = <String, Object?>{
      'publicKey': <String, Object?>{
        'challenge': challenge,
        if (_rpId.isNotEmpty) 'rpId': _rpId,
        'userVerification': 'preferred',
        'timeout': 60000,
      },
    };

    try {
      final assertion = await _credentialsGet(options.jsify() as JSAny).toDart;
      return assertion != null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Passkey authenticate failed: $e');
      }
      return false;
    }
  }

  Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rnd.nextInt(256)),
    );
  }
}

@JS('window.PublicKeyCredential')
external JSAny? get _publicKeyCredential;

@JS('navigator.credentials.create')
external JSPromise<JSAny?> _credentialsCreate(JSAny options);

@JS('navigator.credentials.get')
external JSPromise<JSAny?> _credentialsGet(JSAny options);
