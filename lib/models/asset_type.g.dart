// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssetTypeFieldSchema _$AssetTypeFieldSchemaFromJson(
  Map<String, dynamic> json,
) => _AssetTypeFieldSchema(
  key: json['key'] as String,
  label: json['label'] as String,
  type: json['type'] as String,
  isEncrypted: json['isEncrypted'] as bool? ?? false,
  isRequired: json['isRequired'] as bool? ?? false,
  options:
      (json['options'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$AssetTypeFieldSchemaToJson(
  _AssetTypeFieldSchema instance,
) => <String, dynamic>{
  'key': instance.key,
  'label': instance.label,
  'type': instance.type,
  'isEncrypted': instance.isEncrypted,
  'isRequired': instance.isRequired,
  'options': instance.options,
};

_AssetType _$AssetTypeFromJson(Map<String, dynamic> json) => _AssetType(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
  fieldSchema:
      (json['fieldSchema'] as List<dynamic>?)
          ?.map((e) => AssetTypeFieldSchema.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  isBuiltIn: json['isBuiltIn'] as bool? ?? false,
);

Map<String, dynamic> _$AssetTypeToJson(_AssetType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'fieldSchema': instance.fieldSchema,
      'isBuiltIn': instance.isBuiltIn,
    };
