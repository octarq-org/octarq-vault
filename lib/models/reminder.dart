import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder.freezed.dart';
part 'reminder.g.dart';

@freezed
abstract class Reminder with _$Reminder {
  const factory Reminder({
    required String id,
    required String assetId,
    required String triggerType, // e.g. 'expiration', 'recurring'
    required int offsetDays,
    @Default([]) List<String> channels,
    @Default(false) bool isRecurring,
  }) = _Reminder;

  factory Reminder.fromJson(Map<String, dynamic> json) => _$ReminderFromJson(json);
}
