import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/asset_type.dart';
import '../services/e2ee_sync_service.dart';
import '../utils/default_asset_types.dart';
import 'auth_provider.dart';
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
  List<AssetType> _defaultsForCurrentLocale() =>
      getDefaultAssetTypes(ref.read(localeProvider));

  @override
  List<AssetType> build() {
    final locale = ref.watch(localeProvider);
    ref.listen(localeProvider, (prev, next) {
      if (prev != next) Future.microtask(() => loadCustomTypes());
    });
    ref.listen(authProvider, (previous, next) {
      if (previous == AuthState.unlocked &&
          (next == AuthState.locked || next == AuthState.unsetup)) {
        state = [...getDefaultAssetTypes(locale)];
      }
    });
    return [...getDefaultAssetTypes(locale)];
  }

  /// Web (and import .enc): set custom types from snapshot; built-ins stay.
  /// On non-Web also persists custom types to SQLite.
  Future<void> setCustomTypesFromSnapshot(List<AssetType> customTypes) async {
    state = [..._defaultsForCurrentLocale(), ...customTypes];
    if (kIsWeb) return;
    await _ensureTypesDb(ref);
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
  }

  Future<void> loadCustomTypes() async {
    final defaults = _defaultsForCurrentLocale();
    if (kIsWeb) {
      state = [...defaults];
      return;
    }
    await _ensureTypesDb(ref);
    final dbService = ref.read(databaseServiceProvider);
    final records = await dbService.getCustomAssetTypes();

    final customTypes = records.map((record) {
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
    }).toList();

    state = [...defaults, ...customTypes];
  }

  Future<void> addCustomType(AssetType type) async {
    if (!kIsWeb) {
      await _ensureTypesDb(ref);
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

  Future<void> deleteCustomType(String id) async {
    if (!kIsWeb) {
      await _ensureTypesDb(ref);
      final dbService = ref.read(databaseServiceProvider);
      await dbService.deleteAssetType(id);

      // Record oplog entry for asset type delete
      await dbService.recordAssetTypeOperation(id, OpType.delete, payload: {});
    }
    await loadCustomTypes();
  }
}
