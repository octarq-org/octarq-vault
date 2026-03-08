// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AssetTypeFieldSchemaImpl _$$AssetTypeFieldSchemaImplFromJson(
  Map<String, dynamic> json,
) => _$AssetTypeFieldSchemaImpl(
  key: json['key'] as String,
  label: json['label'] as String,
  type: json['type'] as String,
  isEncrypted: json['isEncrypted'] as bool? ?? false,
  isRequired: json['isRequired'] as bool? ?? false,
);

Map<String, dynamic> _$$AssetTypeFieldSchemaImplToJson(
  _$AssetTypeFieldSchemaImpl instance,
) => <String, dynamic>{
  'key': instance.key,
  'label': instance.label,
  'type': instance.type,
  'isEncrypted': instance.isEncrypted,
  'isRequired': instance.isRequired,
};

_$AssetTypeImpl _$$AssetTypeImplFromJson(Map<String, dynamic> json) =>
    _$AssetTypeImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      fieldSchema:
          (json['fieldSchema'] as List<dynamic>?)
              ?.map(
                (e) => AssetTypeFieldSchema.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );

Map<String, dynamic> _$$AssetTypeImplToJson(_$AssetTypeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'fieldSchema': instance.fieldSchema,
      'isBuiltIn': instance.isBuiltIn,
    };
