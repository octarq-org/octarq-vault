// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssetField _$AssetFieldFromJson(Map<String, dynamic> json) => _AssetField(
  id: json['id'] as String,
  assetId: json['assetId'] as String,
  key: json['key'] as String,
  valueEnc: json['valueEnc'] as String,
  iv: json['iv'] as String,
  isSensitive: json['isSensitive'] as bool? ?? false,
);

Map<String, dynamic> _$AssetFieldToJson(_AssetField instance) =>
    <String, dynamic>{
      'id': instance.id,
      'assetId': instance.assetId,
      'key': instance.key,
      'valueEnc': instance.valueEnc,
      'iv': instance.iv,
      'isSensitive': instance.isSensitive,
    };
