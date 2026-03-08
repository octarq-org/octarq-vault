import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:asset_vault/models/asset_type.dart';
import 'package:asset_vault/providers/asset_types_provider.dart';
import 'package:asset_vault/utils/default_asset_types.dart';

void main() {
  group('AssetTypesNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state contains all default asset types', () {
      final types = container.read(assetTypesProvider);
      expect(types.length, equals(defaultAssetTypes.length));
    });

    test('initial state contains expected built-in types', () {
      final types = container.read(assetTypesProvider);
      final typeNames = types.map((t) => t.name).toList();
      
      expect(typeNames, contains('域名 (Domain)'));
      expect(typeNames, contains('SSL 证书'));
      expect(typeNames, contains('VPS / 云服务器'));
      expect(typeNames, contains('邮箱账号'));
      expect(typeNames, contains('平台账号'));
      expect(typeNames, contains('银行卡 / 信用卡'));
      expect(typeNames, contains('API Key / Token'));
      expect(typeNames, contains('SaaS 订阅'));
    });

    test('all default types are marked as built-in', () {
      final types = container.read(assetTypesProvider);
      for (final type in types) {
        expect(type.isBuiltIn, isTrue, reason: '${type.name} should be built-in');
      }
    });

    test('domain type has expected field schema', () {
      final types = container.read(assetTypesProvider);
      final domain = types.firstWhere((t) => t.id == 'type_domain');

      expect(domain.fieldSchema.length, equals(5));

      final registrarField = domain.fieldSchema.firstWhere((f) => f.key == 'registrar');
      expect(registrarField.isRequired, isTrue);
      expect(registrarField.type, equals('text'));
    });

    test('email type has encrypted password field', () {
      final types = container.read(assetTypesProvider);
      final email = types.firstWhere((t) => t.id == 'type_email');

      final passwordField = email.fieldSchema.firstWhere((f) => f.key == 'password');
      expect(passwordField.isEncrypted, isTrue);
      expect(passwordField.isRequired, isTrue);
      expect(passwordField.type, equals('password'));
    });

    test('API key type has encrypted api_key field', () {
      final types = container.read(assetTypesProvider);
      final apiKey = types.firstWhere((t) => t.id == 'type_apikey');

      final keyField = apiKey.fieldSchema.firstWhere((f) => f.key == 'api_key');
      expect(keyField.isEncrypted, isTrue);
      expect(keyField.type, equals('password'));
    });

    test('bank card type has encrypted card_number and cvv fields', () {
      final types = container.read(assetTypesProvider);
      final bankCard = types.firstWhere((t) => t.id == 'type_bankcard');

      final cardNumber = bankCard.fieldSchema.firstWhere((f) => f.key == 'card_number');
      expect(cardNumber.isEncrypted, isTrue);

      final cvv = bankCard.fieldSchema.firstWhere((f) => f.key == 'cvv');
      expect(cvv.isEncrypted, isTrue);
    });
  });

  group('AssetTypeFieldSchema', () {
    test('JSON roundtrip', () {
      const schema = AssetTypeFieldSchema(
        key: 'test_field',
        label: 'Test Label',
        type: 'password',
        isEncrypted: true,
        isRequired: true,
      );

      final json = schema.toJson();
      final restored = AssetTypeFieldSchema.fromJson(json);

      expect(restored.key, equals('test_field'));
      expect(restored.label, equals('Test Label'));
      expect(restored.type, equals('password'));
      expect(restored.isEncrypted, isTrue);
      expect(restored.isRequired, isTrue);
    });

    test('defaults for optional fields', () {
      const schema = AssetTypeFieldSchema(
        key: 'simple',
        label: 'Simple Field',
        type: 'text',
      );

      expect(schema.isEncrypted, isFalse);
      expect(schema.isRequired, isFalse);
    });
  });

  group('AssetType', () {
    test('JSON roundtrip', () {
      const type = AssetType(
        id: 'custom_1',
        name: 'Custom Type',
        icon: 'star',
        isBuiltIn: false,
        fieldSchema: [
          AssetTypeFieldSchema(key: 'field1', label: 'Field 1', type: 'text'),
          AssetTypeFieldSchema(key: 'secret', label: 'Secret', type: 'password', isEncrypted: true),
        ],
      );

      final jsonString = jsonEncode(type.toJson());
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = AssetType.fromJson(jsonMap);

      expect(restored.id, equals('custom_1'));
      expect(restored.name, equals('Custom Type'));
      expect(restored.icon, equals('star'));
      expect(restored.isBuiltIn, isFalse);
      expect(restored.fieldSchema.length, equals(2));
      expect(restored.fieldSchema[1].isEncrypted, isTrue);
    });
  });
}
