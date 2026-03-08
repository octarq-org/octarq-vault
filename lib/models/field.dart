import 'package:freezed_annotation/freezed_annotation.dart';

part 'field.freezed.dart';
part 'field.g.dart';

@freezed
class AssetField with _$AssetField {
  const factory AssetField({
    required String id,
    required String assetId,
    required String key,
    required String valueEnc, // Base64 encoded AES-GCM string
    required String iv, // Base64 encoded Initialization vector
    @Default(false) bool isSensitive,
  }) = _AssetField;

  factory AssetField.fromJson(Map<String, dynamic> json) => _$AssetFieldFromJson(json);
}
