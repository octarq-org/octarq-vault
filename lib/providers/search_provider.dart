import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/asset.dart';
import 'assets_provider.dart';
import 'asset_types_provider.dart';
import 'auth_provider.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() {
    ref.listen(authProvider, (previous, next) {
      if (previous == AuthState.unlocked &&
          (next == AuthState.locked || next == AuthState.unsetup)) {
        state = '';
      }
    });
    return '';
  }

  void updateQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

class SearchOverlayVisibleNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(authProvider, (previous, next) {
      if (previous == AuthState.unlocked &&
          (next == AuthState.locked || next == AuthState.unsetup)) {
        state = false;
      }
    });
    return false;
  }

  void setVisible(bool value) => state = value;
}

/// When true, show search dropdown in the main layout (in-tree, not overlay).
final searchOverlayVisibleProvider =
    NotifierProvider<SearchOverlayVisibleNotifier, bool>(
      () => SearchOverlayVisibleNotifier(),
    );

/// Max number of asset suggestions in the dropdown.
const int kSearchSuggestionsLimit = 8;

/// Matching assets for current search query (same filter logic as list, no archive filter).
final searchSuggestionsProvider = Provider<List<Asset>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return [];
  final assets = ref.watch(assetsProvider);
  final filtered = assets.where((a) {
    if (a.isArchived) return false;
    final matchName = a.name.toLowerCase().contains(query);
    final matchTag = a.tags.any((t) => t.name.toLowerCase().contains(query));
    // Search field labels (key) and non-sensitive values.
    // valueEnc contains plaintext for non-sensitive fields.
    final matchField = a.fields.any(
      (f) =>
          !f.isSensitive &&
          (f.key.toLowerCase().contains(query) ||
              f.valueEnc.toLowerCase().contains(query)),
    );
    return matchName || matchTag || matchField;
  }).toList();
  filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return filtered.take(kSearchSuggestionsLimit).toList();
});

/// Total count of matches (for "view all N").
final searchSuggestionsTotalCountProvider = Provider<int>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return 0;
  final assets = ref.watch(assetsProvider);
  return assets.where((a) {
    if (a.isArchived) return false;
    final matchName = a.name.toLowerCase().contains(query);
    final matchTag = a.tags.any((t) => t.name.toLowerCase().contains(query));
    // Search field labels (key) and non-sensitive values.
    final matchField = a.fields.any(
      (f) =>
          !f.isSensitive &&
          (f.key.toLowerCase().contains(query) ||
              f.valueEnc.toLowerCase().contains(query)),
    );
    return matchName || matchTag || matchField;
  }).length;
});

/// Matching category (asset type) ids for current query.
final searchMatchingCategoryIdsProvider = Provider<List<String>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return [];
  final types = ref.watch(assetTypesProvider);
  return types
      .where((t) => t.name.toLowerCase().contains(query))
      .map((t) => t.id)
      .toList();
});
