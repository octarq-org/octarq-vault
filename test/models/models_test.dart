import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:octarq_vault/models/asset.dart';
import 'package:octarq_vault/models/field.dart';
import 'package:octarq_vault/models/tag.dart';
import 'package:octarq_vault/models/reminder.dart';

void main() {
  group('Asset model', () {
    test('creates with required fields', () {
      const asset = Asset(
        id: 'asset-1',
        typeId: 'type_domain',
        name: 'example.com',
        createdAt: 1700000000000,
        updatedAt: 1700000000000,
      );

      expect(asset.id, equals('asset-1'));
      expect(asset.typeId, equals('type_domain'));
      expect(asset.name, equals('example.com'));
      expect(asset.isArchived, isFalse);
      expect(asset.fields, isEmpty);
      expect(asset.tags, isEmpty);
      expect(asset.reminders, isEmpty);
      expect(asset.expireAt, isNull);
    });

    test('creates with all fields', () {
      final asset = Asset(
        id: 'asset-2',
        typeId: 'type_vps',
        name: 'My VPS',
        expireAt: 1710000000000,
        createdAt: 1700000000000,
        updatedAt: 1700000000000,
        isArchived: true,
        fields: [
          const AssetField(
            id: 'f1',
            assetId: 'asset-2',
            key: 'provider',
            valueEnc: 'DigitalOcean',
            iv: '',
            isSensitive: false,
          ),
        ],
        tags: [const Tag(id: 'tag1', name: 'production', color: '#FF0000')],
      );

      expect(asset.isArchived, isTrue);
      expect(asset.fields.length, equals(1));
      expect(asset.tags.length, equals(1));
      expect(asset.expireAt, equals(1710000000000));
    });

    test('JSON roundtrip', () {
      const asset = Asset(
        id: 'asset-json',
        typeId: 'type_email',
        name: 'test@email.com',
        createdAt: 1700000000000,
        updatedAt: 1700000000000,
        isArchived: false,
        fields: [
          AssetField(
            id: 'f1',
            assetId: 'asset-json',
            key: 'provider',
            valueEnc: 'Gmail',
            iv: '',
            isSensitive: false,
          ),
        ],
      );

      // Use jsonEncode/jsonDecode to simulate real serialization
      final jsonString = jsonEncode(asset.toJson());
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = Asset.fromJson(jsonMap);

      expect(restored.id, equals(asset.id));
      expect(restored.typeId, equals(asset.typeId));
      expect(restored.name, equals(asset.name));
      expect(restored.isArchived, equals(asset.isArchived));
      expect(restored.fields.length, equals(1));
      expect(restored.fields.first.key, equals('provider'));
    });

    test('copyWith works', () {
      const original = Asset(
        id: 'asset-copy',
        typeId: 'type_domain',
        name: 'old-name.com',
        createdAt: 1700000000000,
        updatedAt: 1700000000000,
      );

      final updated = original.copyWith(name: 'new-name.com', isArchived: true);

      expect(updated.name, equals('new-name.com'));
      expect(updated.isArchived, isTrue);
      expect(updated.id, equals(original.id)); // unchanged
      expect(updated.typeId, equals(original.typeId)); // unchanged
    });
  });

  group('AssetField model', () {
    test('creates with all fields', () {
      const field = AssetField(
        id: 'field-1',
        assetId: 'asset-1',
        key: 'password',
        valueEnc: 'encrypted-base64',
        iv: 'iv-base64',
        isSensitive: true,
      );

      expect(field.isSensitive, isTrue);
      expect(field.valueEnc, equals('encrypted-base64'));
    });

    test('defaults isSensitive to false', () {
      const field = AssetField(
        id: 'field-2',
        assetId: 'asset-1',
        key: 'name',
        valueEnc: 'plaintext',
        iv: '',
      );

      expect(field.isSensitive, isFalse);
    });

    test('JSON roundtrip', () {
      const field = AssetField(
        id: 'f-json',
        assetId: 'a-1',
        key: 'api_key',
        valueEnc: 'enc-data',
        iv: 'iv-data',
        isSensitive: true,
      );

      final json = field.toJson();
      final restored = AssetField.fromJson(json);

      expect(restored.id, equals(field.id));
      expect(restored.key, equals(field.key));
      expect(restored.isSensitive, isTrue);
    });
  });

  group('Tag model', () {
    test('creates correctly', () {
      const tag = Tag(id: 't1', name: 'production', color: '#FF5733');
      expect(tag.name, equals('production'));
      expect(tag.color, equals('#FF5733'));
    });

    test('JSON roundtrip', () {
      const tag = Tag(id: 't-json', name: 'test', color: '#000000');
      final json = tag.toJson();
      final restored = Tag.fromJson(json);
      expect(restored.id, equals(tag.id));
      expect(restored.name, equals(tag.name));
    });
  });

  group('Reminder model', () {
    test('creates correctly', () {
      const reminder = Reminder(
        id: 'r1',
        assetId: 'a1',
        triggerType: 'expiration',
        offsetDays: 7,
        channels: ['push'],
      );

      expect(reminder.triggerType, equals('expiration'));
      expect(reminder.offsetDays, equals(7));
      expect(reminder.isRecurring, isFalse);
    });

    test('JSON roundtrip', () {
      const reminder = Reminder(
        id: 'r-json',
        assetId: 'a-json',
        triggerType: 'billing',
        offsetDays: 14,
        channels: ['push', 'email'],
        isRecurring: true,
      );

      final json = reminder.toJson();
      final restored = Reminder.fromJson(json);

      expect(restored.id, equals(reminder.id));
      expect(restored.triggerType, equals('billing'));
      expect(restored.isRecurring, isTrue);
    });
  });
}
