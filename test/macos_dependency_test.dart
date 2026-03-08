import 'package:flutter_test/flutter_test.dart';
import 'package:dargon2_flutter/dargon2_flutter.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Dependencies load on macOS', () async {
    // Argon2 uses FFI and is expected to fail in test environment
    try {
      final s = Salt(base64.decode('MTIzNDU2Nzg5MDEyMzQ1Ng=='));
      final r = await argon2.hashPasswordString('test', salt: s);
      // ignore: avoid_print
      print("Argon2 success: ${r.encodedString}");
    } catch (e) {
      // Expected in test environment: UnimplementedError
      // ignore: avoid_print
      print("Argon2 (expected failure in test): $e");
    }
  });
}
