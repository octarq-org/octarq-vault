import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_type.freezed.dart';
part 'asset_type.g.dart';

@freezed
abstract class AssetTypeFieldSchema with _$AssetTypeFieldSchema {
  const factory AssetTypeFieldSchema({
    required String key,
    required String label,
    required String type, // 'text', 'password', 'date', 'number', 'select'
    @Default(false) bool isEncrypted,
    @Default(false) bool isRequired,
    @Default([]) List<String> options, // for type == 'select'
  }) = _AssetTypeFieldSchema;

  factory AssetTypeFieldSchema.fromJson(Map<String, dynamic> json) => _$AssetTypeFieldSchemaFromJson(json);
}

@freezed
abstract class AssetType with _$AssetType {
  const factory AssetType({
    required String id,
    required String name,
    required String icon,
    @Default([]) List<AssetTypeFieldSchema> fieldSchema,
    @Default(false) bool isBuiltIn,
  }) = _AssetType;

  factory AssetType.fromJson(Map<String, dynamic> json) => _$AssetTypeFromJson(json);
}
