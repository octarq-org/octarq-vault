import 'package:freezed_annotation/freezed_annotation.dart';
import 'field.dart';
import 'tag.dart';
import 'reminder.dart';

part 'asset.freezed.dart';
part 'asset.g.dart';

@freezed
abstract class Asset with _$Asset {
  const factory Asset({
    required String id,
    required String typeId,
    required String name,
    int? expireAt,
    required int createdAt,
    required int updatedAt,
    @Default(false) bool isArchived,
    @Default([]) List<AssetField> fields,
    @Default([]) List<Tag> tags,
    @Default([]) List<Reminder> reminders,
  }) = _Asset;

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
}
