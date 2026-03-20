// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:asset_vault/models/asset.dart';
import 'package:asset_vault/models/tag.dart';
import 'package:asset_vault/providers/assets_provider.dart';
import 'package:asset_vault/utils/tombstone_registry.dart';

// ---------------------------------------------------------------------------
// Fake notifier
//
// Bypasses SQLite and sync so we can exercise the in-memory state mutations
// in isolation.  The state logic itself (add/update/delete/archive/batch) is
// reimplemented here identically to the real notifier; the tombstone logic
// delegates to the extracted TombstoneRegistry so we know both parts agree.
// ---------------------------------------------------------------------------

class _FakeAssetsNotifier extends AssetsNotifier {
  _FakeAssetsNotifier(this._initial);

  final List<Asset> _initial;
  final _fakeRegistry = TombstoneRegistry();

  @override
  List<Asset> build() => List<Asset>.from(_initial);

  // --- No-op I/O overrides ---

  @override
  Future<void> loadAssets() async {}

  // --- State-only mutations (same logic as real notifier, no DB / no sync) ---

  @override
  Future<void> addAsset(Asset asset) async {
    state = [...state, asset];
  }

  @override
  Future<void> batchAddAssets(List<Asset> assets) async {
    if (assets.isEmpty) return;
    state = [...state, ...assets];
  }

  @override
  Future<void> updateAsset(Asset updatedAsset) async {
    state = [
      for (final a in state)
        if (a.id == updatedAsset.id) updatedAsset else a,
    ];
  }

  @override
  Future<void> deleteAsset(String id) async {
    state = state.where((a) => a.id != id).toList();
    _fakeRegistry.record(id, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<void> archiveAsset(String id) async {
    final asset = state.firstWhere((a) => a.id == id);
    await updateAsset(asset.copyWith(isArchived: true));
  }

  @override
  Future<void> unarchiveAsset(String id) async {
    final asset = state.firstWhere((a) => a.id == id);
    await updateAsset(asset.copyWith(isArchived: false));
  }

  @override
  Future<void> batchArchive(List<String> ids) async {
    for (final id in ids) {
      await archiveAsset(id);
    }
  }

  @override
  Future<void> batchDelete(List<String> ids) async {
    for (final id in ids) {
      await deleteAsset(id);
    }
  }

  @override
  Future<void> batchAddTag(List<String> assetIds, Tag tag) async {
    for (final id in assetIds) {
      final asset = state.firstWhere((a) => a.id == id);
      if (!asset.tags.any((t) => t.id == tag.id)) {
        await updateAsset(asset.copyWith(tags: [...asset.tags, tag]));
      }
    }
  }

  /// Expose the registry so tests can inspect tombstone state.
  TombstoneRegistry get tombstones => _fakeRegistry;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Asset _asset({
  required String id,
  String name = 'Test Asset',
  bool isArchived = false,
  List<Tag> tags = const [],
  int? updatedAt,
}) {
  final ts = updatedAt ?? DateTime.now().millisecondsSinceEpoch;
  return Asset(
    id: id,
    typeId: 'type_generic',
    name: name,
    createdAt: ts,
    updatedAt: ts,
    isArchived: isArchived,
    tags: tags,
  );
}

ProviderContainer _container(_FakeAssetsNotifier notifier) {
  return ProviderContainer(
    overrides: [assetsProvider.overrideWith(() => notifier)],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AssetsNotifier (state mutations)', () {
    group('addAsset', () {
      test('appends asset to empty state', () async {
        final notifier = _FakeAssetsNotifier([]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        await container.read(assetsProvider.notifier).addAsset(_asset(id: '1'));

        expect(container.read(assetsProvider).map((a) => a.id), equals(['1']));
      });

      test(
        'appends to existing state without touching existing assets',
        () async {
          final existing = _asset(id: 'old');
          final notifier = _FakeAssetsNotifier([existing]);
          final container = _container(notifier);
          addTearDown(container.dispose);

          await container
              .read(assetsProvider.notifier)
              .addAsset(_asset(id: 'new'));

          final ids = container.read(assetsProvider).map((a) => a.id).toList();
          expect(ids, equals(['old', 'new']));
        },
      );
    });

    group('batchAddAssets', () {
      test('adds all assets in one call', () async {
        final notifier = _FakeAssetsNotifier([]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        await container.read(assetsProvider.notifier).batchAddAssets([
          _asset(id: 'a'),
          _asset(id: 'b'),
          _asset(id: 'c'),
        ]);

        final ids = container.read(assetsProvider).map((a) => a.id).toList();
        expect(ids, equals(['a', 'b', 'c']));
      });

      test('no-op on empty list', () async {
        final notifier = _FakeAssetsNotifier([_asset(id: 'x')]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        await container.read(assetsProvider.notifier).batchAddAssets([]);

        expect(container.read(assetsProvider).length, equals(1));
      });
    });

    group('updateAsset', () {
      test('replaces asset with matching id', () async {
        final original = _asset(id: '1', name: 'Original');
        final notifier = _FakeAssetsNotifier([original, _asset(id: '2')]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        final updated = original.copyWith(name: 'Updated');
        await container.read(assetsProvider.notifier).updateAsset(updated);

        final assets = container.read(assetsProvider);
        expect(assets.firstWhere((a) => a.id == '1').name, equals('Updated'));
        expect(assets.length, equals(2));
      });

      test('does not affect other assets', () async {
        final a1 = _asset(id: '1', name: 'One');
        final a2 = _asset(id: '2', name: 'Two');
        final notifier = _FakeAssetsNotifier([a1, a2]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        await container
            .read(assetsProvider.notifier)
            .updateAsset(a1.copyWith(name: 'One Modified'));

        expect(
          container.read(assetsProvider).firstWhere((a) => a.id == '2').name,
          equals('Two'),
        );
      });
    });

    group('deleteAsset', () {
      test('removes asset with matching id', () async {
        final notifier = _FakeAssetsNotifier([
          _asset(id: '1'),
          _asset(id: '2'),
        ]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        await container.read(assetsProvider.notifier).deleteAsset('1');

        final ids = container.read(assetsProvider).map((a) => a.id).toList();
        expect(ids, equals(['2']));
      });

      test('records a tombstone for the deleted id', () async {
        final fake = _FakeAssetsNotifier([_asset(id: 'del')]);
        final container = _container(fake);
        addTearDown(container.dispose);

        await container.read(assetsProvider.notifier).deleteAsset('del');

        expect(fake.tombstones.contains('del'), isTrue);
      });

      test('leaves state empty after deleting last asset', () async {
        final notifier = _FakeAssetsNotifier([_asset(id: 'only')]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        await container.read(assetsProvider.notifier).deleteAsset('only');

        expect(container.read(assetsProvider), isEmpty);
      });
    });

    group('batchDelete', () {
      test('removes all specified assets', () async {
        final notifier = _FakeAssetsNotifier([
          _asset(id: '1'),
          _asset(id: '2'),
          _asset(id: '3'),
        ]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        await container.read(assetsProvider.notifier).batchDelete(['1', '3']);

        final ids = container.read(assetsProvider).map((a) => a.id).toList();
        expect(ids, equals(['2']));
      });
    });

    group('archiveAsset / unarchiveAsset', () {
      test('archiveAsset sets isArchived to true', () async {
        final notifier = _FakeAssetsNotifier([_asset(id: '1')]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        await container.read(assetsProvider.notifier).archiveAsset('1');

        expect(container.read(assetsProvider).single.isArchived, isTrue);
      });

      test('unarchiveAsset sets isArchived to false', () async {
        final notifier = _FakeAssetsNotifier([
          _asset(id: '1', isArchived: true),
        ]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        await container.read(assetsProvider.notifier).unarchiveAsset('1');

        expect(container.read(assetsProvider).single.isArchived, isFalse);
      });

      test('archive then unarchive restores the asset', () async {
        final notifier = _FakeAssetsNotifier([_asset(id: '1')]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        final n = container.read(assetsProvider.notifier);
        await n.archiveAsset('1');
        expect(container.read(assetsProvider).single.isArchived, isTrue);

        await n.unarchiveAsset('1');
        expect(container.read(assetsProvider).single.isArchived, isFalse);
      });
    });

    group('batchArchive', () {
      test('archives multiple assets in one call', () async {
        final notifier = _FakeAssetsNotifier([
          _asset(id: 'a'),
          _asset(id: 'b'),
          _asset(id: 'c'),
        ]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        await container.read(assetsProvider.notifier).batchArchive(['a', 'c']);

        final assets = container.read(assetsProvider);
        expect(assets.firstWhere((x) => x.id == 'a').isArchived, isTrue);
        expect(assets.firstWhere((x) => x.id == 'b').isArchived, isFalse);
        expect(assets.firstWhere((x) => x.id == 'c').isArchived, isTrue);
      });
    });

    group('batchAddTag', () {
      test('adds tag to specified assets', () async {
        final notifier = _FakeAssetsNotifier([
          _asset(id: '1'),
          _asset(id: '2'),
        ]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        const tag = Tag(id: 'tag-1', name: 'Important', color: '#FF0000');
        await container.read(assetsProvider.notifier).batchAddTag(['1'], tag);

        final assets = container.read(assetsProvider);
        expect(
          assets
              .firstWhere((a) => a.id == '1')
              .tags
              .any((t) => t.id == 'tag-1'),
          isTrue,
        );
        expect(assets.firstWhere((a) => a.id == '2').tags, isEmpty);
      });

      test('does not add duplicate tag to the same asset', () async {
        const tag = Tag(id: 'tag-1', name: 'Dup', color: '#000000');
        final notifier = _FakeAssetsNotifier([
          _asset(id: '1', tags: [tag]),
        ]);
        final container = _container(notifier);
        addTearDown(container.dispose);

        await container.read(assetsProvider.notifier).batchAddTag(['1'], tag);

        expect(container.read(assetsProvider).single.tags.length, equals(1));
      });
    });
  });
}
