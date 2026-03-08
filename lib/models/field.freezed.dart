// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'field.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssetField {

 String get id; String get assetId; String get key; String get valueEnc;// Base64 encoded AES-GCM string
 String get iv;// Base64 encoded Initialization vector
 bool get isSensitive;
/// Create a copy of AssetField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetFieldCopyWith<AssetField> get copyWith => _$AssetFieldCopyWithImpl<AssetField>(this as AssetField, _$identity);

  /// Serializes this AssetField to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetField&&(identical(other.id, id) || other.id == id)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.key, key) || other.key == key)&&(identical(other.valueEnc, valueEnc) || other.valueEnc == valueEnc)&&(identical(other.iv, iv) || other.iv == iv)&&(identical(other.isSensitive, isSensitive) || other.isSensitive == isSensitive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,assetId,key,valueEnc,iv,isSensitive);

@override
String toString() {
  return 'AssetField(id: $id, assetId: $assetId, key: $key, valueEnc: $valueEnc, iv: $iv, isSensitive: $isSensitive)';
}


}

/// @nodoc
abstract mixin class $AssetFieldCopyWith<$Res>  {
  factory $AssetFieldCopyWith(AssetField value, $Res Function(AssetField) _then) = _$AssetFieldCopyWithImpl;
@useResult
$Res call({
 String id, String assetId, String key, String valueEnc, String iv, bool isSensitive
});




}
/// @nodoc
class _$AssetFieldCopyWithImpl<$Res>
    implements $AssetFieldCopyWith<$Res> {
  _$AssetFieldCopyWithImpl(this._self, this._then);

  final AssetField _self;
  final $Res Function(AssetField) _then;

/// Create a copy of AssetField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? assetId = null,Object? key = null,Object? valueEnc = null,Object? iv = null,Object? isSensitive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,valueEnc: null == valueEnc ? _self.valueEnc : valueEnc // ignore: cast_nullable_to_non_nullable
as String,iv: null == iv ? _self.iv : iv // ignore: cast_nullable_to_non_nullable
as String,isSensitive: null == isSensitive ? _self.isSensitive : isSensitive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetField].
extension AssetFieldPatterns on AssetField {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetField() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetField value)  $default,){
final _that = this;
switch (_that) {
case _AssetField():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetField value)?  $default,){
final _that = this;
switch (_that) {
case _AssetField() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String assetId,  String key,  String valueEnc,  String iv,  bool isSensitive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetField() when $default != null:
return $default(_that.id,_that.assetId,_that.key,_that.valueEnc,_that.iv,_that.isSensitive);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String assetId,  String key,  String valueEnc,  String iv,  bool isSensitive)  $default,) {final _that = this;
switch (_that) {
case _AssetField():
return $default(_that.id,_that.assetId,_that.key,_that.valueEnc,_that.iv,_that.isSensitive);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String assetId,  String key,  String valueEnc,  String iv,  bool isSensitive)?  $default,) {final _that = this;
switch (_that) {
case _AssetField() when $default != null:
return $default(_that.id,_that.assetId,_that.key,_that.valueEnc,_that.iv,_that.isSensitive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssetField implements AssetField {
  const _AssetField({required this.id, required this.assetId, required this.key, required this.valueEnc, required this.iv, this.isSensitive = false});
  factory _AssetField.fromJson(Map<String, dynamic> json) => _$AssetFieldFromJson(json);

@override final  String id;
@override final  String assetId;
@override final  String key;
@override final  String valueEnc;
// Base64 encoded AES-GCM string
@override final  String iv;
// Base64 encoded Initialization vector
@override@JsonKey() final  bool isSensitive;

/// Create a copy of AssetField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetFieldCopyWith<_AssetField> get copyWith => __$AssetFieldCopyWithImpl<_AssetField>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetFieldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetField&&(identical(other.id, id) || other.id == id)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.key, key) || other.key == key)&&(identical(other.valueEnc, valueEnc) || other.valueEnc == valueEnc)&&(identical(other.iv, iv) || other.iv == iv)&&(identical(other.isSensitive, isSensitive) || other.isSensitive == isSensitive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,assetId,key,valueEnc,iv,isSensitive);

@override
String toString() {
  return 'AssetField(id: $id, assetId: $assetId, key: $key, valueEnc: $valueEnc, iv: $iv, isSensitive: $isSensitive)';
}


}

/// @nodoc
abstract mixin class _$AssetFieldCopyWith<$Res> implements $AssetFieldCopyWith<$Res> {
  factory _$AssetFieldCopyWith(_AssetField value, $Res Function(_AssetField) _then) = __$AssetFieldCopyWithImpl;
@override @useResult
$Res call({
 String id, String assetId, String key, String valueEnc, String iv, bool isSensitive
});




}
/// @nodoc
class __$AssetFieldCopyWithImpl<$Res>
    implements _$AssetFieldCopyWith<$Res> {
  __$AssetFieldCopyWithImpl(this._self, this._then);

  final _AssetField _self;
  final $Res Function(_AssetField) _then;

/// Create a copy of AssetField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? assetId = null,Object? key = null,Object? valueEnc = null,Object? iv = null,Object? isSensitive = null,}) {
  return _then(_AssetField(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,valueEnc: null == valueEnc ? _self.valueEnc : valueEnc // ignore: cast_nullable_to_non_nullable
as String,iv: null == iv ? _self.iv : iv // ignore: cast_nullable_to_non_nullable
as String,isSensitive: null == isSensitive ? _self.isSensitive : isSensitive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
