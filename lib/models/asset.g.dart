// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AssetImpl _$$AssetImplFromJson(Map<String, dynamic> json) => _$AssetImpl(
  id: json['id'] as String,
  typeId: json['typeId'] as String,
  name: json['name'] as String,
  expireAt: (json['expireAt'] as num?)?.toInt(),
  createdAt: (json['createdAt'] as num).toInt(),
  updatedAt: (json['updatedAt'] as num).toInt(),
  isArchived: json['isArchived'] as bool? ?? false,
  fields:
      (json['fields'] as List<dynamic>?)
          ?.map((e) => AssetField.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  reminders:
      (json['reminders'] as List<dynamic>?)
          ?.map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$AssetImplToJson(_$AssetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'typeId': instance.typeId,
      'name': instance.name,
      'expireAt': instance.expireAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'isArchived': instance.isArchived,
      'fields': instance.fields,
      'tags': instance.tags,
      'reminders': instance.reminders,
    };
