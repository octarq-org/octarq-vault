import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:octarq_vault/models/asset.dart';
import 'package:octarq_vault/models/field.dart';
import 'package:octarq_vault/models/asset_type.dart';
import 'package:octarq_vault/providers/asset_types_provider.dart';
import 'package:octarq_vault/providers/assets_provider.dart';
import 'package:octarq_vault/providers/auth_provider.dart';
import 'package:octarq_vault/providers/locale_preference_provider.dart';
import 'package:octarq_vault/providers/service_providers.dart';
import 'package:octarq_vault/services/database_service.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';
import 'package:octarq_vault/utils/default_asset_types.dart';

class _ZhLocalePreferenceNotifier extends LocalePreferenceNotifier {
  @override
  String build() => 'zh';
}

class _UnlockedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState.unlocked;
}

class _MockAssetTypesDatabaseService extends DatabaseService {
  final List<Map<String, dynamic>> assetTypes = [];
  bool deleteAllCalled = false;

  @override
  bool get isOpen => true;

  @override
  Future<List<Map<String, dynamic>>> getCustomAssetTypes() async {
    return assetTypes.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> insertAssetType(Map<String, dynamic> typeData) async {
    assetTypes.removeWhere((item) => item['id'] == typeData['id']);
    assetTypes.add(Map<String, dynamic>.from(typeData));
  }

  @override
  Future<void> deleteAssetType(String id) async {
    assetTypes.removeWhere((item) => item['id'] == id);
  }

  @override
  Future<void> deleteAllAssetTypes() async {
    deleteAllCalled = true;
    assetTypes.clear();
  }

  @override
  Future<OpLogEntry> appendOpLog(OpLogEntry entry) async => entry;
}

class _AssetsUsingDomainTypeNotifier extends AssetsNotifier {
  @override
  List<Asset> build() {
    return [
      Asset(
        id: 'asset_using_domain',
        typeId: 'type_domain',
        name: 'Domain 1',
        createdAt: 1,
        updatedAt: 1,
        fields: const <AssetField>[],
      ),
    ];
  }
}

void main() {
  group('AssetTypesNotifier', () {
    late ProviderContainer container;
    late _MockAssetTypesDatabaseService mockDb;

    setUp(() {
      mockDb = _MockAssetTypesDatabaseService();
      container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_UnlockedAuthNotifier.new),
          localePreferenceProvider.overrideWith(
            _ZhLocalePreferenceNotifier.new,
          ),
          databaseServiceProvider.overrideWithValue(mockDb),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state contains all default asset types', () {
      final types = container.read(assetTypesProvider);
      expect(
        types.length,
        equals(getDefaultAssetTypes(const Locale('zh')).length),
      );
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
        expect(
          type.isBuiltIn,
          isTrue,
          reason: '${type.name} should be built-in',
        );
      }
    });

    test('domain type has expected field schema', () {
      final types = container.read(assetTypesProvider);
      final domain = types.firstWhere((t) => t.id == 'type_domain');

      expect(domain.fieldSchema.length, equals(5));

      final registrarField = domain.fieldSchema.firstWhere(
        (f) => f.key == 'registrar',
      );
      expect(registrarField.isRequired, isTrue);
      expect(registrarField.type, equals('text'));
    });

    test('email type has encrypted password field', () {
      final types = container.read(assetTypesProvider);
      final email = types.firstWhere((t) => t.id == 'type_email');

      final passwordField = email.fieldSchema.firstWhere(
        (f) => f.key == 'password',
      );
      expect(passwordField.isEncrypted, isTrue);
      expect(passwordField.isRequired, isFalse);
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

      final cardNumber = bankCard.fieldSchema.firstWhere(
        (f) => f.key == 'card_number',
      );
      expect(cardNumber.isEncrypted, isTrue);

      final cvv = bankCard.fieldSchema.firstWhere((f) => f.key == 'cvv');
      expect(cvv.isEncrypted, isTrue);
    });

    test(
      'loadCustomTypes appends persisted custom types after defaults',
      () async {
        mockDb.assetTypes.add({
          'id': 'custom_server',
          'name': '自定义服务器',
          'icon': 'dns',
          'updated_at': 777,
          'field_schema': jsonEncode([
            {
              'key': 'endpoint',
              'label': 'Endpoint',
              'type': 'text',
              'isEncrypted': false,
              'isRequired': true,
              'options': <String>[],
            },
          ]),
          'is_built_in': 0,
        });

        final notifier = container.read(assetTypesProvider.notifier);
        await notifier.loadCustomTypes();

        final types = container.read(assetTypesProvider);
        final customType = types.firstWhere(
          (type) => type.id == 'custom_server',
        );
        expect(customType.name, equals('自定义服务器'));
        expect(customType.isBuiltIn, isFalse);
        expect(customType.fieldSchema.single.key, equals('endpoint'));
        expect(customType.updatedAt, equals(777));
        expect(
          types.length,
          equals(getDefaultAssetTypes(const Locale('zh')).length + 1),
        );
      },
    );

    test('addCustomType persists and reloads custom type', () async {
      final notifier = container.read(assetTypesProvider.notifier);
      const customType = AssetType(
        id: 'custom_api',
        name: '自定义 API',
        icon: 'api',
        isBuiltIn: false,
        fieldSchema: [
          AssetTypeFieldSchema(
            key: 'token',
            label: 'Token',
            type: 'password',
            isEncrypted: true,
          ),
        ],
      );

      await notifier.addCustomType(customType);

      final stored = mockDb.assetTypes.singleWhere(
        (type) => type['id'] == 'custom_api',
      );
      expect(stored['name'], equals('自定义 API'));
      expect(stored['updated_at'], equals(0));

      final types = container.read(assetTypesProvider);
      expect(types.any((type) => type.id == 'custom_api'), isTrue);
    });

    test(
      'deleteCustomType removes persisted custom type and reloads defaults only',
      () async {
        mockDb.assetTypes.add({
          'id': 'custom_delete_me',
          'name': '删除我',
          'icon': 'delete',
          'field_schema': jsonEncode(<Map<String, dynamic>>[]),
          'is_built_in': 0,
          'updated_at': 0,
        });

        final notifier = container.read(assetTypesProvider.notifier);
        await notifier.loadCustomTypes();
        expect(
          container
              .read(assetTypesProvider)
              .any((type) => type.id == 'custom_delete_me'),
          isTrue,
        );

        await notifier.deleteCustomType('custom_delete_me');

        expect(mockDb.assetTypes, isEmpty);
        expect(
          container
              .read(assetTypesProvider)
              .any((type) => type.id == 'custom_delete_me'),
          isFalse,
        );
      },
    );

    test(
      'setCustomTypesFromSnapshot replaces previously persisted custom types',
      () async {
        mockDb.assetTypes.addAll([
          {
            'id': 'legacy_1',
            'name': 'Legacy 1',
            'icon': 'old',
            'field_schema': jsonEncode(<Map<String, dynamic>>[]),
            'is_built_in': 0,
            'updated_at': 0,
          },
          {
            'id': 'legacy_2',
            'name': 'Legacy 2',
            'icon': 'old',
            'field_schema': jsonEncode(<Map<String, dynamic>>[]),
            'is_built_in': 0,
            'updated_at': 0,
          },
        ]);

        final notifier = container.read(assetTypesProvider.notifier);
        await notifier.setCustomTypesFromSnapshot(const [
          AssetType(
            id: 'snapshot_type',
            name: 'Snapshot Type',
            icon: 'snap',
            isBuiltIn: false,
            updatedAt: 999,
            fieldSchema: [
              AssetTypeFieldSchema(key: 'url', label: 'URL', type: 'text'),
            ],
          ),
        ]);

        expect(mockDb.deleteAllCalled, isTrue);
        expect(mockDb.assetTypes, hasLength(1));
        expect(mockDb.assetTypes.single['id'], equals('snapshot_type'));
        expect(mockDb.assetTypes.single['updated_at'], equals(999));
        expect(
          container
              .read(assetTypesProvider)
              .any((type) => type.id == 'snapshot_type'),
          isTrue,
        );
        expect(
          container
              .read(assetTypesProvider)
              .any((type) => type.id == 'legacy_1'),
          isFalse,
        );
      },
    );

    test('loadCustomTypes uses DB record to override built-in by id', () async {
      mockDb.assetTypes.add({
        'id': 'type_domain',
        'name': 'Domain (Overridden)',
        'icon': 'cloud',
        'updated_at': 888,
        'field_schema': jsonEncode([
          {
            'key': 'provider',
            'label': 'Provider',
            'type': 'text',
            'isEncrypted': false,
            'isRequired': true,
            'options': <String>[],
          },
        ]),
        'is_built_in': 1,
      });

      final notifier = container.read(assetTypesProvider.notifier);
      await notifier.loadCustomTypes();

      final types = container.read(assetTypesProvider);
      final domain = types.firstWhere((type) => type.id == 'type_domain');
      expect(domain.name, equals('Domain (Overridden)'));
      expect(domain.icon, equals('cloud'));
      expect(domain.updatedAt, equals(888));
      expect(domain.fieldSchema.single.key, equals('provider'));
    });

    test(
      'loadCustomTypes hides built-in when tombstone marker exists in DB',
      () async {
        mockDb.assetTypes.add({
          'id': 'type_domain',
          'name': '__deleted_builtin__:type_domain',
          'icon': 'language',
          'updated_at': 999,
          'field_schema': jsonEncode(<Map<String, dynamic>>[]),
          'is_built_in': 1,
        });

        final notifier = container.read(assetTypesProvider.notifier);
        await notifier.loadCustomTypes();

        final types = container.read(assetTypesProvider);
        expect(types.any((type) => type.id == 'type_domain'), isFalse);
      },
    );

    test('deleteTypeIfUnused writes built-in tombstone marker', () async {
      final notifier = container.read(assetTypesProvider.notifier);
      final result = await notifier.deleteTypeIfUnused('type_domain');

      expect(result.deleted, isTrue);
      final tombstone = mockDb.assetTypes.singleWhere(
        (row) => row['id'] == 'type_domain',
      );
      expect(
        (tombstone['name'] as String).startsWith('__deleted_builtin__:'),
        isTrue,
      );
    });

    test('deleteTypeIfUnused blocks when type is used by assets', () async {
      final usedContainer = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_UnlockedAuthNotifier.new),
          localePreferenceProvider.overrideWith(
            _ZhLocalePreferenceNotifier.new,
          ),
          databaseServiceProvider.overrideWithValue(mockDb),
          assetsProvider.overrideWith(_AssetsUsingDomainTypeNotifier.new),
        ],
      );
      addTearDown(usedContainer.dispose);

      final result = await usedContainer
          .read(assetTypesProvider.notifier)
          .deleteTypeIfUnused('type_domain');

      expect(result.deleted, isFalse);
      expect(result.usageCount, equals(1));
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
          AssetTypeFieldSchema(
            key: 'secret',
            label: 'Secret',
            type: 'password',
            isEncrypted: true,
          ),
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
      expect(restored.updatedAt, equals(0));
    });

    test('JSON roundtrip preserves updatedAt', () {
      const type = AssetType(
        id: 'custom_1',
        name: 'Custom Type',
        icon: 'star',
        isBuiltIn: false,
        updatedAt: 12345,
        fieldSchema: [],
      );

      final restored = AssetType.fromJson(type.toJson());
      expect(restored.updatedAt, equals(12345));
    });
  });
}
