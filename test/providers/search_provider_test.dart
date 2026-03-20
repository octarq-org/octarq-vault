import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:octarq_vault/models/asset.dart';
import 'package:octarq_vault/models/asset_type.dart';
import 'package:octarq_vault/models/field.dart';
import 'package:octarq_vault/models/tag.dart';
import 'package:octarq_vault/providers/asset_types_provider.dart';
import 'package:octarq_vault/providers/assets_provider.dart';
import 'package:octarq_vault/providers/search_provider.dart';

class _FakeAssetsNotifier extends AssetsNotifier {
  _FakeAssetsNotifier(this._assets);

  final List<Asset> _assets;

  @override
  List<Asset> build() => _assets;
}

class _FakeAssetTypesNotifier extends AssetTypesNotifier {
  _FakeAssetTypesNotifier(this._types);

  final List<AssetType> _types;

  @override
  List<AssetType> build() => _types;
}

Asset _asset({
  required String id,
  required String name,
  required int createdAt,
  bool isArchived = false,
  List<Tag> tags = const [],
  List<AssetField> fields = const [],
}) {
  return Asset(
    id: id,
    typeId: 'type_generic',
    name: name,
    createdAt: createdAt,
    updatedAt: createdAt,
    isArchived: isArchived,
    tags: tags,
    fields: fields,
  );
}

void main() {
  group('search providers', () {
    test('returns no suggestions for empty or whitespace-only query', () {
      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _FakeAssetsNotifier(const [])),
          assetTypesProvider.overrideWith(
            () => _FakeAssetTypesNotifier(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).updateQuery('   ');

      expect(container.read(searchSuggestionsProvider), isEmpty);
      expect(container.read(searchSuggestionsTotalCountProvider), equals(0));
      expect(container.read(searchMatchingCategoryIdsProvider), isEmpty);
    });

    test('matches query by name, tag, and non-sensitive field', () {
      final assets = [
        _asset(id: '1', name: 'Primary Domain', createdAt: 10),
        _asset(
          id: '2',
          name: 'Mail Account',
          createdAt: 20,
          tags: const [Tag(id: 'tag-1', name: 'Domain Ops', color: '#111111')],
        ),
        _asset(
          id: '3',
          name: 'Server',
          createdAt: 30,
          fields: const [
            AssetField(
              id: 'field-1',
              assetId: '3',
              key: 'domain_certificate',
              valueEnc: 'base64encodedciphertext==',
              iv: 'base64IV==',
            ),
          ],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _FakeAssetsNotifier(assets)),
          assetTypesProvider.overrideWith(
            () => _FakeAssetTypesNotifier(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).updateQuery('  domain  ');

      final suggestions = container.read(searchSuggestionsProvider);
      expect(suggestions.map((asset) => asset.id), equals(['3', '2', '1']));
      expect(container.read(searchSuggestionsTotalCountProvider), equals(3));
    });

    test('excludes archived assets and sensitive-field-only matches', () {
      final assets = [
        _asset(
          id: 'archived',
          name: 'Archived Match',
          createdAt: 10,
          isArchived: true,
        ),
        _asset(
          id: 'sensitive',
          name: 'Production Secret',
          createdAt: 20,
          fields: const [
            AssetField(
              id: 'field-2',
              assetId: 'sensitive',
              key: 'token',
              valueEnc: 'super-secret-token',
              iv: 'base64IV==',
              isSensitive: true,
            ),
          ],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _FakeAssetsNotifier(assets)),
          assetTypesProvider.overrideWith(
            () => _FakeAssetTypesNotifier(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).updateQuery('token');

      expect(container.read(searchSuggestionsProvider), isEmpty);
      expect(container.read(searchSuggestionsTotalCountProvider), equals(0));
    });

    test('limits suggestions to 8 while keeping full match count', () {
      final assets = List.generate(
        10,
        (index) =>
            _asset(id: 'asset-$index', name: 'Domain $index', createdAt: index),
      );

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _FakeAssetsNotifier(assets)),
          assetTypesProvider.overrideWith(
            () => _FakeAssetTypesNotifier(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).updateQuery('domain');

      final suggestions = container.read(searchSuggestionsProvider);
      expect(suggestions.length, equals(kSearchSuggestionsLimit));
      expect(
        suggestions.map((asset) => asset.id).toList(),
        equals([
          'asset-9',
          'asset-8',
          'asset-7',
          'asset-6',
          'asset-5',
          'asset-4',
          'asset-3',
          'asset-2',
        ]),
      );
      expect(container.read(searchSuggestionsTotalCountProvider), equals(10));
    });

    test('matches category ids case-insensitively after trimming query', () {
      final types = const [
        AssetType(id: 'domain', name: 'Domain', icon: 'globe'),
        AssetType(id: 'ssl', name: 'SSL Certificate', icon: 'lock'),
        AssetType(id: 'server', name: 'Server', icon: 'server'),
      ];

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _FakeAssetsNotifier(const [])),
          assetTypesProvider.overrideWith(() => _FakeAssetTypesNotifier(types)),
        ],
      );
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).updateQuery('  sSl ');

      expect(
        container.read(searchMatchingCategoryIdsProvider),
        equals(['ssl']),
      );
    });
  });
}
