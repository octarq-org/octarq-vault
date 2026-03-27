import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/asset_type.dart';
import '../services/e2ee_sync_service.dart';
import '../utils/default_asset_types.dart';
import 'auth_provider.dart';
import 'assets_provider.dart';
import 'locale_provider.dart';
import 'service_providers.dart';

Future<void> _ensureTypesDb(Ref ref) async {
  if (kIsWeb) return;
  final dbSvc = ref.read(databaseServiceProvider);
  if (dbSvc.isOpen) return;
  final key = ref.read(encryptionServiceProvider).masterKey;
  await dbSvc.ensureOpen(key);
}

final assetTypesProvider =
    NotifierProvider<AssetTypesNotifier, List<AssetType>>(() {
      return AssetTypesNotifier();
    });

class AssetTypesNotifier extends Notifier<List<AssetType>> {
  static const String _deletedBuiltInNamePrefix = '__deleted_builtin__:';

  List<AssetType> _defaultsForCurrentLocale() =>
      getDefaultAssetTypes(ref.read(localeProvider));
  bool _didLoadAfterUnlock = false;

  bool _isDeletedBuiltInMarker(AssetType type) {
    return type.isBuiltIn && type.name.startsWith(_deletedBuiltInNamePrefix);
  }

  List<AssetType> _mergeDefaultsWithPersisted(
    List<AssetType> defaults,
    List<AssetType> persisted,
  ) {
    final merged = <String, AssetType>{for (final d in defaults) d.id: d};
    final deletedBuiltInIds = <String>{};

    for (final item in persisted) {
      if (_isDeletedBuiltInMarker(item)) {
        deletedBuiltInIds.add(item.id);
        merged.remove(item.id);
        continue;
      }
      merged[item.id] = item;
    }

    return merged.values
        .where((t) => !deletedBuiltInIds.contains(t.id))
        .toList(growable: false);
  }

  List<AssetType> _extractPersistedFromState(List<AssetType> defaults) {
    final defaultsById = {for (final d in defaults) d.id: d};
    return state
        .where((item) {
          if (_isDeletedBuiltInMarker(item)) return true;
          final defaultItem = defaultsById[item.id];
          if (defaultItem == null) return true;
          return defaultItem != item;
        })
        .toList(growable: false);
  }

  List<AssetType> persistedTypesForSync() {
    return _extractPersistedFromState(_defaultsForCurrentLocale());
  }

  @override
  List<AssetType> build() {
    final locale = ref.watch(localeProvider);
    final authState = ref.watch(authProvider);
    ref.listen(localeProvider, (prev, next) {
      if (prev != next) Future.microtask(() => loadCustomTypes());
    });
    ref.listen(authProvider, (previous, next) {
      if (previous != AuthState.unlocked && next == AuthState.unlocked) {
        _didLoadAfterUnlock = true;
        Future.microtask(() => loadCustomTypes());
      }
      if (previous == AuthState.unlocked &&
          (next == AuthState.locked || next == AuthState.unsetup)) {
        _didLoadAfterUnlock = false;
        state = [...getDefaultAssetTypes(locale)];
      }
    });
    if (authState == AuthState.unlocked && !_didLoadAfterUnlock) {
      _didLoadAfterUnlock = true;
      Future.microtask(() => loadCustomTypes());
    }
    return [...getDefaultAssetTypes(locale)];
  }

  /// Web (and import .enc): set custom types from snapshot; built-ins stay.
  /// On non-Web also persists custom types to SQLite.
  Future<void> setCustomTypesFromSnapshot(List<AssetType> customTypes) async {
    if (!ref.mounted) return;
    final defaults = _defaultsForCurrentLocale();
    if (kIsWeb) {
      state = _mergeDefaultsWithPersisted(defaults, customTypes);
      return;
    }
    await _ensureTypesDb(ref);
    if (!ref.mounted) return;
    final dbService = ref.read(databaseServiceProvider);
    await dbService.deleteAllAssetTypes();
    for (final type in customTypes) {
      final fieldSchemaJson = jsonEncode(
        type.fieldSchema.map((e) => e.toJson()).toList(),
      );
      await dbService.insertAssetType({
        'id': type.id,
        'name': type.name,
        'icon': type.icon,
        'field_schema': fieldSchemaJson,
        'is_built_in': type.isBuiltIn ? 1 : 0,
        'updated_at': type.updatedAt,
      });
    }
    if (!ref.mounted) return;
    state = _mergeDefaultsWithPersisted(defaults, customTypes);
  }

  Future<void> loadCustomTypes() async {
    final defaults = _defaultsForCurrentLocale();
    if (!ref.mounted) return;
    if (kIsWeb) {
      final persisted = _extractPersistedFromState(defaults);
      if (!ref.mounted) return;
      state = _mergeDefaultsWithPersisted(defaults, persisted);
      return;
    }
    await _ensureTypesDb(ref);
    if (!ref.mounted) return;
    final dbService = ref.read(databaseServiceProvider);
    final records = await dbService.getCustomAssetTypes();
    if (!ref.mounted) return;

    final persistedTypes = records
        .map((record) {
          final fieldSchemaJson =
              jsonDecode(record['field_schema'] as String) as List;
          final fieldSchema = fieldSchemaJson
              .map((e) => AssetTypeFieldSchema.fromJson(e))
              .toList();

          return AssetType(
            id: record['id'] as String,
            name: record['name'] as String,
            icon: record['icon'] as String,
            isBuiltIn: (record['is_built_in'] as int) == 1,
            fieldSchema: fieldSchema,
            updatedAt: (record['updated_at'] as int?) ?? 0,
          );
        })
        .toList(growable: false);

    if (!ref.mounted) return;
    state = _mergeDefaultsWithPersisted(defaults, persistedTypes);
  }

  Future<void> addCustomType(AssetType type) async {
    if (!kIsWeb) {
      await _ensureTypesDb(ref);
      if (!ref.mounted) return;
      final dbService = ref.read(databaseServiceProvider);
      final fieldSchemaJson = jsonEncode(
        type.fieldSchema.map((e) => e.toJson()).toList(),
      );

      await dbService.insertAssetType({
        'id': type.id,
        'name': type.name,
        'icon': type.icon,
        'field_schema': fieldSchemaJson,
        'is_built_in': type.isBuiltIn ? 1 : 0,
        'updated_at': type.updatedAt,
      });

      // Record oplog entry for asset type upsert
      await dbService.recordAssetTypeOperation(
        type.id,
        OpType.upsert,
        payload: type.toJson(),
      );
    }

    await loadCustomTypes();
  }

  Future<void> updateCustomType(AssetType type) async {
    if (!kIsWeb) {
      await _ensureTypesDb(ref);
      if (!ref.mounted) return;
      final dbService = ref.read(databaseServiceProvider);
      final fieldSchemaJson = jsonEncode(
        type.fieldSchema.map((e) => e.toJson()).toList(),
      );

      await dbService.insertAssetType({
        'id': type.id,
        'name': type.name,
        'icon': type.icon,
        'field_schema': fieldSchemaJson,
        'is_built_in': type.isBuiltIn ? 1 : 0,
        'updated_at': type.updatedAt,
      });

      await dbService.recordAssetTypeOperation(
        type.id,
        OpType.upsert,
        payload: type.toJson(),
      );
    }

    await loadCustomTypes();
  }

  Future<void> upsertType(AssetType type) async {
    if (kIsWeb) {
      final defaults = _defaultsForCurrentLocale();
      final persisted = _extractPersistedFromState(
        defaults,
      ).where((t) => t.id != type.id).toList(growable: false);
      if (!ref.mounted) return;
      state = _mergeDefaultsWithPersisted(defaults, [...persisted, type]);
      return;
    } else {
      await _ensureTypesDb(ref);
      if (!ref.mounted) return;
      final dbService = ref.read(databaseServiceProvider);
      final fieldSchemaJson = jsonEncode(
        type.fieldSchema.map((e) => e.toJson()).toList(),
      );
      await dbService.insertAssetType({
        'id': type.id,
        'name': type.name,
        'icon': type.icon,
        'field_schema': fieldSchemaJson,
        'is_built_in': type.isBuiltIn ? 1 : 0,
        'updated_at': type.updatedAt,
      });
      await dbService.recordAssetTypeOperation(
        type.id,
        OpType.upsert,
        payload: type.toJson(),
      );
    }
    await loadCustomTypes();
  }

  Future<DeleteTypeResult> deleteTypeIfUnused(String id) async {
    if (!ref.mounted) return const DeleteTypeResult.deleted();
    final usageCount = ref
        .read(assetsProvider)
        .where((asset) => asset.typeId == id)
        .length;
    if (usageCount > 0) {
      return DeleteTypeResult.blocked(usageCount: usageCount);
    }

    final type = state.where((t) => t.id == id).firstOrNull;
    if (type == null) {
      return const DeleteTypeResult.deleted();
    }

    if (kIsWeb) {
      if (type.isBuiltIn) {
        final marker = type.copyWith(
          name: '$_deletedBuiltInNamePrefix${type.id}',
          fieldSchema: const [],
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        if (!ref.mounted) return const DeleteTypeResult.deleted();
        state = _mergeDefaultsWithPersisted(_defaultsForCurrentLocale(), [
          ..._extractPersistedFromState(
            _defaultsForCurrentLocale(),
          ).where((t) => t.id != id),
          marker,
        ]);
      } else {
        state = state.where((t) => t.id != id).toList(growable: false);
      }
      return const DeleteTypeResult.deleted();
    } else {
      await _ensureTypesDb(ref);
      if (!ref.mounted) return const DeleteTypeResult.deleted();
      final dbService = ref.read(databaseServiceProvider);
      if (type.isBuiltIn) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await dbService.insertAssetType({
          'id': type.id,
          'name': '$_deletedBuiltInNamePrefix${type.id}',
          'icon': type.icon,
          'field_schema': '[]',
          'is_built_in': 1,
          'updated_at': now,
        });
        await dbService.recordAssetTypeOperation(
          id,
          OpType.upsert,
          payload: {
            'id': type.id,
            'name': '$_deletedBuiltInNamePrefix${type.id}',
            'icon': type.icon,
            'fieldSchema': <Map<String, dynamic>>[],
            'isBuiltIn': true,
            'updatedAt': now,
          },
        );
      } else {
        await dbService.deleteAssetType(id);
        await dbService.recordAssetTypeOperation(
          id,
          OpType.delete,
          payload: {},
        );
      }
    }
    await loadCustomTypes();
    return const DeleteTypeResult.deleted();
  }

  Future<void> deleteCustomType(String id) async {
    await deleteTypeIfUnused(id);
  }
}

class DeleteTypeResult {
  final bool deleted;
  final int usageCount;

  const DeleteTypeResult._({required this.deleted, required this.usageCount});

  const DeleteTypeResult.deleted() : this._(deleted: true, usageCount: 0);

  const DeleteTypeResult.blocked({required int usageCount})
    : this._(deleted: false, usageCount: usageCount);
}
