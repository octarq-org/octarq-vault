// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'field.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AssetField _$AssetFieldFromJson(Map<String, dynamic> json) {
  return _AssetField.fromJson(json);
}

/// @nodoc
mixin _$AssetField {
  String get id => throw _privateConstructorUsedError;
  String get assetId => throw _privateConstructorUsedError;
  String get key => throw _privateConstructorUsedError;
  String get valueEnc =>
      throw _privateConstructorUsedError; // Base64 encoded AES-GCM string
  String get iv =>
      throw _privateConstructorUsedError; // Base64 encoded Initialization vector
  bool get isSensitive => throw _privateConstructorUsedError;

  /// Serializes this AssetField to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AssetField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssetFieldCopyWith<AssetField> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssetFieldCopyWith<$Res> {
  factory $AssetFieldCopyWith(
    AssetField value,
    $Res Function(AssetField) then,
  ) = _$AssetFieldCopyWithImpl<$Res, AssetField>;
  @useResult
  $Res call({
    String id,
    String assetId,
    String key,
    String valueEnc,
    String iv,
    bool isSensitive,
  });
}

/// @nodoc
class _$AssetFieldCopyWithImpl<$Res, $Val extends AssetField>
    implements $AssetFieldCopyWith<$Res> {
  _$AssetFieldCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AssetField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? assetId = null,
    Object? key = null,
    Object? valueEnc = null,
    Object? iv = null,
    Object? isSensitive = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            assetId: null == assetId
                ? _value.assetId
                : assetId // ignore: cast_nullable_to_non_nullable
                      as String,
            key: null == key
                ? _value.key
                : key // ignore: cast_nullable_to_non_nullable
                      as String,
            valueEnc: null == valueEnc
                ? _value.valueEnc
                : valueEnc // ignore: cast_nullable_to_non_nullable
                      as String,
            iv: null == iv
                ? _value.iv
                : iv // ignore: cast_nullable_to_non_nullable
                      as String,
            isSensitive: null == isSensitive
                ? _value.isSensitive
                : isSensitive // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AssetFieldImplCopyWith<$Res>
    implements $AssetFieldCopyWith<$Res> {
  factory _$$AssetFieldImplCopyWith(
    _$AssetFieldImpl value,
    $Res Function(_$AssetFieldImpl) then,
  ) = __$$AssetFieldImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String assetId,
    String key,
    String valueEnc,
    String iv,
    bool isSensitive,
  });
}

/// @nodoc
class __$$AssetFieldImplCopyWithImpl<$Res>
    extends _$AssetFieldCopyWithImpl<$Res, _$AssetFieldImpl>
    implements _$$AssetFieldImplCopyWith<$Res> {
  __$$AssetFieldImplCopyWithImpl(
    _$AssetFieldImpl _value,
    $Res Function(_$AssetFieldImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AssetField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? assetId = null,
    Object? key = null,
    Object? valueEnc = null,
    Object? iv = null,
    Object? isSensitive = null,
  }) {
    return _then(
      _$AssetFieldImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        assetId: null == assetId
            ? _value.assetId
            : assetId // ignore: cast_nullable_to_non_nullable
                  as String,
        key: null == key
            ? _value.key
            : key // ignore: cast_nullable_to_non_nullable
                  as String,
        valueEnc: null == valueEnc
            ? _value.valueEnc
            : valueEnc // ignore: cast_nullable_to_non_nullable
                  as String,
        iv: null == iv
            ? _value.iv
            : iv // ignore: cast_nullable_to_non_nullable
                  as String,
        isSensitive: null == isSensitive
            ? _value.isSensitive
            : isSensitive // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AssetFieldImpl implements _AssetField {
  const _$AssetFieldImpl({
    required this.id,
    required this.assetId,
    required this.key,
    required this.valueEnc,
    required this.iv,
    this.isSensitive = false,
  });

  factory _$AssetFieldImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssetFieldImplFromJson(json);

  @override
  final String id;
  @override
  final String assetId;
  @override
  final String key;
  @override
  final String valueEnc;
  // Base64 encoded AES-GCM string
  @override
  final String iv;
  // Base64 encoded Initialization vector
  @override
  @JsonKey()
  final bool isSensitive;

  @override
  String toString() {
    return 'AssetField(id: $id, assetId: $assetId, key: $key, valueEnc: $valueEnc, iv: $iv, isSensitive: $isSensitive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssetFieldImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.assetId, assetId) || other.assetId == assetId) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.valueEnc, valueEnc) ||
                other.valueEnc == valueEnc) &&
            (identical(other.iv, iv) || other.iv == iv) &&
            (identical(other.isSensitive, isSensitive) ||
                other.isSensitive == isSensitive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, assetId, key, valueEnc, iv, isSensitive);

  /// Create a copy of AssetField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssetFieldImplCopyWith<_$AssetFieldImpl> get copyWith =>
      __$$AssetFieldImplCopyWithImpl<_$AssetFieldImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AssetFieldImplToJson(this);
  }
}

abstract class _AssetField implements AssetField {
  const factory _AssetField({
    required final String id,
    required final String assetId,
    required final String key,
    required final String valueEnc,
    required final String iv,
    final bool isSensitive,
  }) = _$AssetFieldImpl;

  factory _AssetField.fromJson(Map<String, dynamic> json) =
      _$AssetFieldImpl.fromJson;

  @override
  String get id;
  @override
  String get assetId;
  @override
  String get key;
  @override
  String get valueEnc; // Base64 encoded AES-GCM string
  @override
  String get iv; // Base64 encoded Initialization vector
  @override
  bool get isSensitive;

  /// Create a copy of AssetField
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssetFieldImplCopyWith<_$AssetFieldImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
