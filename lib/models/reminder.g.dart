// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Reminder _$ReminderFromJson(Map<String, dynamic> json) => _Reminder(
  id: json['id'] as String,
  assetId: json['assetId'] as String,
  triggerType: json['triggerType'] as String,
  offsetDays: (json['offsetDays'] as num).toInt(),
  channels:
      (json['channels'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isRecurring: json['isRecurring'] as bool? ?? false,
);

Map<String, dynamic> _$ReminderToJson(_Reminder instance) => <String, dynamic>{
  'id': instance.id,
  'assetId': instance.assetId,
  'triggerType': instance.triggerType,
  'offsetDays': instance.offsetDays,
  'channels': instance.channels,
  'isRecurring': instance.isRecurring,
};
