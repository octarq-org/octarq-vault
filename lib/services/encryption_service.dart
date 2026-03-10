import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dargon2_flutter/dargon2_flutter.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  Uint8List? _masterKey;
  String? _saltBase64;

  Future<void> deriveKey(String password, String saltBase64) async {
    _saltBase64 = saltBase64;
    final salt = base64.decode(saltBase64);
    final result = await argon2.hashPasswordString(
      password,
      salt: Salt(salt),
      iterations: 3,
      memory: 64 * 1024, // 64 MB
      parallelism: 4,
      length: 32, // 256 bit key
      type: Argon2Type.id,
    );
    _masterKey = Uint8List.fromList(result.rawBytes);
  }

  /// Sets key directly (from Keychain/Secure Storage)
  void setMasterKey(Uint8List key) {
    if (key.length != 32) throw Exception("Key must be 256-bit");
    _masterKey = key;
  }

  Uint8List get masterKey {
    if (_masterKey == null) throw Exception("Key not initialized");
    return _masterKey!;
  }

  void setSalt(String saltBase64) {
    _saltBase64 = saltBase64;
  }

  String get currentSaltBase64 {
    if (_saltBase64 == null) throw Exception("Salt not initialized");
    return _saltBase64!;
  }

  /// Wipe key from memory
  void wipeKey() {
    if (_masterKey != null) {
      for (int i = 0; i < _masterKey!.length; i++) {
        _masterKey![i] = 0;
      }
      _masterKey = null;
    }
    _saltBase64 = null;
  }

  /// Encrypts plaintext using AES-256-GCM with a random IV
  Map<String, String> encryptField(String plaintext) {
    final key = masterKey; // Will throw if not set
    final iv = _generateRandomBytes(12); // Standard for GCM

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key),
          128, // MAC size in bits (16 bytes)
          iv,
          Uint8List(0),
        ),
      );

    final plaintextBytes = utf8.encode(plaintext);
    final cipherText = cipher.process(plaintextBytes);

    return {'valueEnc': base64.encode(cipherText), 'iv': base64.encode(iv)};
  }

  /// Decrypts ciphertext using AES-256-GCM and the supplied IV
  String decryptField(String base64Ciphertext, String base64Iv) {
    final key = masterKey;
    final cipherText = base64.decode(base64Ciphertext);
    final iv = base64.decode(base64Iv);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    final plainTextBytes = cipher.process(cipherText);
    return utf8.decode(plainTextBytes);
  }

  /// Encrypts an entire binary payload (e.g. JSON string as bytes)
  /// Returns a concatenated payload: [IV (12 bytes)] + [Ciphertext + MAC]
  Uint8List encryptBytes(Uint8List plaintextBytes) {
    final key = masterKey;
    final iv = _generateRandomBytes(12);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    final cipherText = cipher.process(plaintextBytes);

    // Concat IV + cipherText so we can write to a single file payload
    final payload = BytesBuilder();
    payload.add(iv);
    payload.add(cipherText);
    return payload.toBytes();
  }

  /// Decrypts a binary payload that was created with encryptBytes()
  /// Expects: [IV (12 bytes)] + [Ciphertext + MAC]
  Uint8List decryptBytes(Uint8List payloadToDecrypt) {
    if (payloadToDecrypt.length <= 12) {
      throw Exception("Payload too small to contain IV");
    }

    final key = masterKey;
    final iv = payloadToDecrypt.sublist(0, 12);
    final cipherText = payloadToDecrypt.sublist(12);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    return cipher.process(cipherText);
  }

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (i) => random.nextInt(256)),
    );
  }

  String generateSaltBase64() {
    return base64.encode(_generateRandomBytes(16));
  }
}
