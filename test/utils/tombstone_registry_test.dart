import 'package:flutter_test/flutter_test.dart';
import 'package:octarq_vault/utils/tombstone_registry.dart';

void main() {
  group('TombstoneRegistry', () {
    late TombstoneRegistry registry;

    setUp(() {
      registry = TombstoneRegistry();
    });

    group('record', () {
      test('records a new tombstone', () {
        registry.record('asset-1', 1000);

        expect(registry.contains('asset-1'), isTrue);
        expect(registry.length, equals(1));
      });

      test('updates when new deletedAt is strictly greater', () {
        registry.record('asset-1', 1000);
        registry.record('asset-1', 2000);

        final list = registry.toList();
        expect(list.single['deletedAt'], equals(2000));
      });

      test('does not update when new deletedAt is equal', () {
        registry.record('asset-1', 1000);
        registry.record('asset-1', 1000);

        final list = registry.toList();
        expect(list.single['deletedAt'], equals(1000));
        expect(registry.length, equals(1));
      });

      test('does not update when new deletedAt is older', () {
        registry.record('asset-1', 2000);
        registry.record('asset-1', 500);

        final list = registry.toList();
        expect(list.single['deletedAt'], equals(2000));
      });

      test('can record multiple distinct asset ids', () {
        registry.record('a', 100);
        registry.record('b', 200);
        registry.record('c', 300);

        expect(registry.length, equals(3));
        expect(registry.contains('a'), isTrue);
        expect(registry.contains('b'), isTrue);
        expect(registry.contains('c'), isTrue);
      });
    });

    group('loadFromList', () {
      test('loads entries from snapshot format', () {
        registry.loadFromList([
          {'id': 'x', 'deletedAt': 500},
          {'id': 'y', 'deletedAt': 600},
        ]);

        expect(registry.length, equals(2));
        expect(registry.contains('x'), isTrue);
        expect(registry.contains('y'), isTrue);
      });

      test('skips entries with null id or deletedAt', () {
        registry.loadFromList([
          {'id': null, 'deletedAt': 100},
          {'id': 'valid', 'deletedAt': null},
          {'id': 'good', 'deletedAt': 500},
        ]);

        expect(registry.length, equals(1));
        expect(registry.contains('good'), isTrue);
      });

      test(
        'applies newer-wins rule when loading on top of existing entries',
        () {
          registry.record('asset-1', 3000);

          // Attempt to load a stale tombstone — should be ignored.
          registry.loadFromList([
            {'id': 'asset-1', 'deletedAt': 1000},
          ]);

          final list = registry.toList();
          expect(list.single['deletedAt'], equals(3000));
        },
      );

      test('loading a fresher tombstone updates the entry', () {
        registry.record('asset-1', 1000);

        registry.loadFromList([
          {'id': 'asset-1', 'deletedAt': 9999},
        ]);

        final list = registry.toList();
        expect(list.single['deletedAt'], equals(9999));
      });

      test(
        'loading into empty registry leaves it empty when list is empty',
        () {
          registry.loadFromList([]);
          expect(registry.isEmpty, isTrue);
        },
      );
    });

    group('shouldDelete', () {
      test('returns true when tombstone deletedAt > asset updatedAt', () {
        registry.record('asset-1', 2000);
        expect(registry.shouldDelete('asset-1', 1000), isTrue);
      });

      test('returns false when tombstone deletedAt == asset updatedAt', () {
        registry.record('asset-1', 1000);
        expect(registry.shouldDelete('asset-1', 1000), isFalse);
      });

      test('returns false when tombstone deletedAt < asset updatedAt', () {
        registry.record('asset-1', 500);
        expect(registry.shouldDelete('asset-1', 1000), isFalse);
      });

      test('returns false for an id with no tombstone', () {
        expect(registry.shouldDelete('unknown-id', 1000), isFalse);
      });
    });

    group('toList', () {
      test('returns empty list when registry is empty', () {
        expect(registry.toList(), isEmpty);
      });

      test('round-trips through loadFromList', () {
        registry.record('a1', 111);
        registry.record('a2', 222);

        final serialized = registry.toList();

        final restored = TombstoneRegistry();
        restored.loadFromList(serialized);

        expect(restored.length, equals(2));
        expect(restored.contains('a1'), isTrue);
        expect(restored.contains('a2'), isTrue);
        expect(
          restored.toList().map((e) => e['deletedAt']),
          containsAll([111, 222]),
        );
      });

      test('each entry has id and deletedAt keys', () {
        registry.record('asset-x', 42);

        final entry = registry.toList().single;
        expect(entry['id'], equals('asset-x'));
        expect(entry['deletedAt'], equals(42));
      });
    });

    group('isEmpty / length', () {
      test('isEmpty is true for a new registry', () {
        expect(registry.isEmpty, isTrue);
        expect(registry.length, equals(0));
      });

      test('isEmpty is false after recording', () {
        registry.record('id', 1);
        expect(registry.isEmpty, isFalse);
        expect(registry.length, equals(1));
      });
    });

    group('toListForSync', () {
      test('drops tombstones older than retention vs nowMs', () {
        const now = 1_000_000_000;
        const day = 86400000;
        registry.record('fresh', now - day);
        registry.record('stale', now - 40 * day);
        final pruned = registry.toListForSync(
          retention: const Duration(days: 30),
          nowMs: now,
        );
        expect(pruned.map((e) => e['id']).toList(), equals(['fresh']));
      });

      test('full registry unchanged after toListForSync', () {
        registry.record('a', 1);
        registry.toListForSync(nowMs: 1_000_000_000);
        expect(registry.length, equals(1));
      });
    });
  });
}
