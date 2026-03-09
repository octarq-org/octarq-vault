import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/asset_type.dart';
import '../utils/default_asset_types.dart';
import 'service_providers.dart';

final assetTypesProvider =
    NotifierProvider<AssetTypesNotifier, List<AssetType>>(() {
      return AssetTypesNotifier();
    });

class AssetTypesNotifier extends Notifier<List<AssetType>> {
  @override
  List<AssetType> build() {
    return [...defaultAssetTypes];
  }

  Future<void> loadCustomTypes() async {
    if (kIsWeb) {
      state = [...defaultAssetTypes];
      return;
    }
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
      );
    }).toList();

    state = [...defaultAssetTypes, ...customTypes];
  }

  Future<void> addCustomType(AssetType type) async {
    if (!kIsWeb) {
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
      });
    }

    await loadCustomTypes();
  }

  Future<void> deleteCustomType(String id) async {
    if (!kIsWeb) {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.deleteAssetType(id);
    }
    await loadCustomTypes();
  }
}
