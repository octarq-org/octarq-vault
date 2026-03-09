import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:asset_vault/services/encryption_service.dart';

void main() {
  late EncryptionService service;

  setUp(() {
    service = EncryptionService();
  });

  group('Salt generation', () {
    test('generates base64 encoded salt', () {
      final salt = service.generateSaltBase64();
      expect(salt, isNotEmpty);
      // Should be valid base64
      final decoded = base64.decode(salt);
      expect(decoded.length, 16); // 16 bytes
    });

    test('generates unique salts', () {
      final salt1 = service.generateSaltBase64();
      final salt2 = service.generateSaltBase64();
      expect(salt1, isNot(equals(salt2)));
    });
  });

  group('Master key management', () {
    test('setMasterKey stores a 256-bit key', () {
      final key = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        key[i] = i;
      }

      service.setMasterKey(key);
      expect(service.masterKey, equals(key));
    });

    test('setMasterKey rejects non-256-bit key', () {
      final shortKey = Uint8List(16);
      expect(() => service.setMasterKey(shortKey), throwsException);
    });

    test('masterKey throws when not initialized', () {
      expect(() => service.masterKey, throwsException);
    });

    test('wipeKey zeros out and nullifies the key', () {
      final key = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        key[i] = i + 1;
      }

      service.setMasterKey(key);
      expect(service.masterKey, isNotNull);

      service.wipeKey();
      expect(() => service.masterKey, throwsException);
    });

    test('wipeKey is safe to call when no key is set', () {
      // Should not throw
      service.wipeKey();
    });
  });

  group('AES-256-GCM encrypt/decrypt', () {
    setUp(() {
      // Set a deterministic 256-bit key for testing
      final key = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        key[i] = i;
      }
      service.setMasterKey(key);
    });

    test('encrypts and returns valueEnc and iv', () {
      final result = service.encryptField('hello world');
      expect(result, contains('valueEnc'));
      expect(result, contains('iv'));
      expect(result['valueEnc'], isNotEmpty);
      expect(result['iv'], isNotEmpty);
    });

    test('decrypt roundtrip produces original plaintext', () {
      const original = 'my-secret-api-key-12345';
      final encrypted = service.encryptField(original);

      final decrypted = service.decryptField(
        encrypted['valueEnc']!,
        encrypted['iv']!,
      );

      expect(decrypted, equals(original));
    });

    test('handles empty string', () {
      const original = '';
      final encrypted = service.encryptField(original);
      final decrypted = service.decryptField(
        encrypted['valueEnc']!,
        encrypted['iv']!,
      );
      expect(decrypted, equals(original));
    });

    test('handles unicode content', () {
      const original = '密码管理器测试 🔐 пароль';
      final encrypted = service.encryptField(original);
      final decrypted = service.decryptField(
        encrypted['valueEnc']!,
        encrypted['iv']!,
      );
      expect(decrypted, equals(original));
    });

    test('handles long content', () {
      final original = 'x' * 10000;
      final encrypted = service.encryptField(original);
      final decrypted = service.decryptField(
        encrypted['valueEnc']!,
        encrypted['iv']!,
      );
      expect(decrypted, equals(original));
    });

    test('each encryption produces unique IV (different ciphertexts)', () {
      const plaintext = 'same-value';
      final enc1 = service.encryptField(plaintext);
      final enc2 = service.encryptField(plaintext);

      // IVs should differ
      expect(enc1['iv'], isNot(equals(enc2['iv'])));
      // Ciphertexts should also differ due to unique IVs
      expect(enc1['valueEnc'], isNot(equals(enc2['valueEnc'])));
    });

    test('decryption with wrong key fails', () {
      const plaintext = 'secret-data';
      final encrypted = service.encryptField(plaintext);

      // Create new service with different key
      final otherService = EncryptionService();
      final wrongKey = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        wrongKey[i] = 255 - i;
      }
      otherService.setMasterKey(wrongKey);

      expect(
        () =>
            otherService.decryptField(encrypted['valueEnc']!, encrypted['iv']!),
        throwsA(anything),
      );
    });

    test('decryption with tampered ciphertext fails', () {
      const plaintext = 'secret-data';
      final encrypted = service.encryptField(plaintext);

      // Tamper with the ciphertext
      final tamperedBytes = base64.decode(encrypted['valueEnc']!);
      if (tamperedBytes.isNotEmpty) {
        tamperedBytes[0] ^= 0xFF;
      }
      final tamperedEnc = base64.encode(tamperedBytes);

      expect(
        () => service.decryptField(tamperedEnc, encrypted['iv']!),
        throwsA(anything),
      );
    });
  });
}
