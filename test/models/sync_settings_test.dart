import 'package:flutter_test/flutter_test.dart';

import 'package:asset_vault/models/sync_settings.dart';

void main() {
  group('SyncMethodX.fromString', () {
    test('returns none for null, empty, and unknown values', () {
      expect(SyncMethodX.fromString(null), equals(SyncMethod.none));
      expect(SyncMethodX.fromString(''), equals(SyncMethod.none));
      expect(SyncMethodX.fromString('unknown'), equals(SyncMethod.none));
    });

    test('parses valid enum names exactly', () {
      expect(SyncMethodX.fromString('webdav'), equals(SyncMethod.webdav));
      expect(
        SyncMethodX.fromString('googleDrive'),
        equals(SyncMethod.googleDrive),
      );
    });
  });

  group('SyncMethodX.listFromStrings', () {
    test('returns empty list for null and empty inputs', () {
      expect(SyncMethodX.listFromStrings(null), isEmpty);
      expect(SyncMethodX.listFromStrings(const []), isEmpty);
    });

    test('filters invalid values, none, and duplicates', () {
      final methods = SyncMethodX.listFromStrings([
        'webdav',
        'none',
        'invalid',
        'googleDrive',
        'webdav',
        123,
      ]);

      expect(
        methods,
        unorderedEquals([SyncMethod.webdav, SyncMethod.googleDrive]),
      );
    });
  });

  group('SyncSettingsExport', () {
    test('toJsonString and fromJsonString roundtrip', () {
      const settings = SyncSettingsExport(
        syncMethods: ['webdav', 'googleDrive'],
        webdavUrl: 'https://dav.example.com',
      );

      final restored = SyncSettingsExport.fromJsonString(
        settings.toJsonString(),
      );

      expect(restored.syncMethods, equals(['webdav', 'googleDrive']));
      expect(restored.webdavUrl, equals('https://dav.example.com'));
    });

    test('fromJson falls back to legacy syncMethod key', () {
      final restored = SyncSettingsExport.fromJson({
        'syncMethod': 'icloud',
        'webdavUrl': null,
      });

      expect(restored.syncMethods, equals(['icloud']));
      expect(restored.webdavUrl, isNull);
    });

    test('fromJson coerces non-string syncMethods entries to strings', () {
      final restored = SyncSettingsExport.fromJson({
        'syncMethods': ['webdav', 42, true],
      });

      expect(restored.syncMethods, equals(['webdav', '42', 'true']));
    });

    test('fromJson returns empty syncMethods when no relevant keys exist', () {
      final restored = SyncSettingsExport.fromJson({});
      expect(restored.syncMethods, isEmpty);
    });
  });
}
