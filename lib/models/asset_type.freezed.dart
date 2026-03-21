// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssetTypeFieldSchema {

 String get key; String get label; String get type;// 'text', 'password', 'date', 'number', 'select'
 bool get isEncrypted; bool get isRequired; List<String> get options;
/// Create a copy of AssetTypeFieldSchema
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetTypeFieldSchemaCopyWith<AssetTypeFieldSchema> get copyWith => _$AssetTypeFieldSchemaCopyWithImpl<AssetTypeFieldSchema>(this as AssetTypeFieldSchema, _$identity);

  /// Serializes this AssetTypeFieldSchema to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetTypeFieldSchema&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type)&&(identical(other.isEncrypted, isEncrypted) || other.isEncrypted == isEncrypted)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired)&&const DeepCollectionEquality().equals(other.options, options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,label,type,isEncrypted,isRequired,const DeepCollectionEquality().hash(options));

@override
String toString() {
  return 'AssetTypeFieldSchema(key: $key, label: $label, type: $type, isEncrypted: $isEncrypted, isRequired: $isRequired, options: $options)';
}


}

/// @nodoc
abstract mixin class $AssetTypeFieldSchemaCopyWith<$Res>  {
  factory $AssetTypeFieldSchemaCopyWith(AssetTypeFieldSchema value, $Res Function(AssetTypeFieldSchema) _then) = _$AssetTypeFieldSchemaCopyWithImpl;
@useResult
$Res call({
 String key, String label, String type, bool isEncrypted, bool isRequired, List<String> options
});




}
/// @nodoc
class _$AssetTypeFieldSchemaCopyWithImpl<$Res>
    implements $AssetTypeFieldSchemaCopyWith<$Res> {
  _$AssetTypeFieldSchemaCopyWithImpl(this._self, this._then);

  final AssetTypeFieldSchema _self;
  final $Res Function(AssetTypeFieldSchema) _then;

/// Create a copy of AssetTypeFieldSchema
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,Object? type = null,Object? isEncrypted = null,Object? isRequired = null,Object? options = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isEncrypted: null == isEncrypted ? _self.isEncrypted : isEncrypted // ignore: cast_nullable_to_non_nullable
as bool,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetTypeFieldSchema].
extension AssetTypeFieldSchemaPatterns on AssetTypeFieldSchema {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetTypeFieldSchema value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetTypeFieldSchema() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetTypeFieldSchema value)  $default,){
final _that = this;
switch (_that) {
case _AssetTypeFieldSchema():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetTypeFieldSchema value)?  $default,){
final _that = this;
switch (_that) {
case _AssetTypeFieldSchema() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String label,  String type,  bool isEncrypted,  bool isRequired,  List<String> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetTypeFieldSchema() when $default != null:
return $default(_that.key,_that.label,_that.type,_that.isEncrypted,_that.isRequired,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String label,  String type,  bool isEncrypted,  bool isRequired,  List<String> options)  $default,) {final _that = this;
switch (_that) {
case _AssetTypeFieldSchema():
return $default(_that.key,_that.label,_that.type,_that.isEncrypted,_that.isRequired,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String label,  String type,  bool isEncrypted,  bool isRequired,  List<String> options)?  $default,) {final _that = this;
switch (_that) {
case _AssetTypeFieldSchema() when $default != null:
return $default(_that.key,_that.label,_that.type,_that.isEncrypted,_that.isRequired,_that.options);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssetTypeFieldSchema implements AssetTypeFieldSchema {
  const _AssetTypeFieldSchema({required this.key, required this.label, required this.type, this.isEncrypted = false, this.isRequired = false, final  List<String> options = const []}): _options = options;
  factory _AssetTypeFieldSchema.fromJson(Map<String, dynamic> json) => _$AssetTypeFieldSchemaFromJson(json);

@override final  String key;
@override final  String label;
@override final  String type;
// 'text', 'password', 'date', 'number', 'select'
@override@JsonKey() final  bool isEncrypted;
@override@JsonKey() final  bool isRequired;
 final  List<String> _options;
@override@JsonKey() List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of AssetTypeFieldSchema
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetTypeFieldSchemaCopyWith<_AssetTypeFieldSchema> get copyWith => __$AssetTypeFieldSchemaCopyWithImpl<_AssetTypeFieldSchema>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetTypeFieldSchemaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetTypeFieldSchema&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type)&&(identical(other.isEncrypted, isEncrypted) || other.isEncrypted == isEncrypted)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired)&&const DeepCollectionEquality().equals(other._options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,label,type,isEncrypted,isRequired,const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'AssetTypeFieldSchema(key: $key, label: $label, type: $type, isEncrypted: $isEncrypted, isRequired: $isRequired, options: $options)';
}


}

/// @nodoc
abstract mixin class _$AssetTypeFieldSchemaCopyWith<$Res> implements $AssetTypeFieldSchemaCopyWith<$Res> {
  factory _$AssetTypeFieldSchemaCopyWith(_AssetTypeFieldSchema value, $Res Function(_AssetTypeFieldSchema) _then) = __$AssetTypeFieldSchemaCopyWithImpl;
@override @useResult
$Res call({
 String key, String label, String type, bool isEncrypted, bool isRequired, List<String> options
});




}
/// @nodoc
class __$AssetTypeFieldSchemaCopyWithImpl<$Res>
    implements _$AssetTypeFieldSchemaCopyWith<$Res> {
  __$AssetTypeFieldSchemaCopyWithImpl(this._self, this._then);

  final _AssetTypeFieldSchema _self;
  final $Res Function(_AssetTypeFieldSchema) _then;

/// Create a copy of AssetTypeFieldSchema
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,Object? type = null,Object? isEncrypted = null,Object? isRequired = null,Object? options = null,}) {
  return _then(_AssetTypeFieldSchema(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isEncrypted: null == isEncrypted ? _self.isEncrypted : isEncrypted // ignore: cast_nullable_to_non_nullable
as bool,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$AssetType {

 String get id; String get name; String get icon; List<AssetTypeFieldSchema> get fieldSchema; bool get isBuiltIn;/// Milliseconds since epoch; LWW merge for [VaultSnapshot.customAssetTypes].
/// Built-in templates use 0.
 int get updatedAt;
/// Create a copy of AssetType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetTypeCopyWith<AssetType> get copyWith => _$AssetTypeCopyWithImpl<AssetType>(this as AssetType, _$identity);

  /// Serializes this AssetType to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetType&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other.fieldSchema, fieldSchema)&&(identical(other.isBuiltIn, isBuiltIn) || other.isBuiltIn == isBuiltIn)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,const DeepCollectionEquality().hash(fieldSchema),isBuiltIn,updatedAt);

@override
String toString() {
  return 'AssetType(id: $id, name: $name, icon: $icon, fieldSchema: $fieldSchema, isBuiltIn: $isBuiltIn, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AssetTypeCopyWith<$Res>  {
  factory $AssetTypeCopyWith(AssetType value, $Res Function(AssetType) _then) = _$AssetTypeCopyWithImpl;
@useResult
$Res call({
 String id, String name, String icon, List<AssetTypeFieldSchema> fieldSchema, bool isBuiltIn, int updatedAt
});




}
/// @nodoc
class _$AssetTypeCopyWithImpl<$Res>
    implements $AssetTypeCopyWith<$Res> {
  _$AssetTypeCopyWithImpl(this._self, this._then);

  final AssetType _self;
  final $Res Function(AssetType) _then;

/// Create a copy of AssetType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? fieldSchema = null,Object? isBuiltIn = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,fieldSchema: null == fieldSchema ? _self.fieldSchema : fieldSchema // ignore: cast_nullable_to_non_nullable
as List<AssetTypeFieldSchema>,isBuiltIn: null == isBuiltIn ? _self.isBuiltIn : isBuiltIn // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetType].
extension AssetTypePatterns on AssetType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetType value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetType() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetType value)  $default,){
final _that = this;
switch (_that) {
case _AssetType():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetType value)?  $default,){
final _that = this;
switch (_that) {
case _AssetType() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String icon,  List<AssetTypeFieldSchema> fieldSchema,  bool isBuiltIn,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetType() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.fieldSchema,_that.isBuiltIn,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String icon,  List<AssetTypeFieldSchema> fieldSchema,  bool isBuiltIn,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AssetType():
return $default(_that.id,_that.name,_that.icon,_that.fieldSchema,_that.isBuiltIn,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String icon,  List<AssetTypeFieldSchema> fieldSchema,  bool isBuiltIn,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AssetType() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.fieldSchema,_that.isBuiltIn,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssetType implements AssetType {
  const _AssetType({required this.id, required this.name, required this.icon, final  List<AssetTypeFieldSchema> fieldSchema = const [], this.isBuiltIn = false, this.updatedAt = 0}): _fieldSchema = fieldSchema;
  factory _AssetType.fromJson(Map<String, dynamic> json) => _$AssetTypeFromJson(json);

@override final  String id;
@override final  String name;
@override final  String icon;
 final  List<AssetTypeFieldSchema> _fieldSchema;
@override@JsonKey() List<AssetTypeFieldSchema> get fieldSchema {
  if (_fieldSchema is EqualUnmodifiableListView) return _fieldSchema;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fieldSchema);
}

@override@JsonKey() final  bool isBuiltIn;
/// Milliseconds since epoch; LWW merge for [VaultSnapshot.customAssetTypes].
/// Built-in templates use 0.
@override@JsonKey() final  int updatedAt;

/// Create a copy of AssetType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetTypeCopyWith<_AssetType> get copyWith => __$AssetTypeCopyWithImpl<_AssetType>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetTypeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetType&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other._fieldSchema, _fieldSchema)&&(identical(other.isBuiltIn, isBuiltIn) || other.isBuiltIn == isBuiltIn)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,const DeepCollectionEquality().hash(_fieldSchema),isBuiltIn,updatedAt);

@override
String toString() {
  return 'AssetType(id: $id, name: $name, icon: $icon, fieldSchema: $fieldSchema, isBuiltIn: $isBuiltIn, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AssetTypeCopyWith<$Res> implements $AssetTypeCopyWith<$Res> {
  factory _$AssetTypeCopyWith(_AssetType value, $Res Function(_AssetType) _then) = __$AssetTypeCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String icon, List<AssetTypeFieldSchema> fieldSchema, bool isBuiltIn, int updatedAt
});




}
/// @nodoc
class __$AssetTypeCopyWithImpl<$Res>
    implements _$AssetTypeCopyWith<$Res> {
  __$AssetTypeCopyWithImpl(this._self, this._then);

  final _AssetType _self;
  final $Res Function(_AssetType) _then;

/// Create a copy of AssetType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? fieldSchema = null,Object? isBuiltIn = null,Object? updatedAt = null,}) {
  return _then(_AssetType(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,fieldSchema: null == fieldSchema ? _self._fieldSchema : fieldSchema // ignore: cast_nullable_to_non_nullable
as List<AssetTypeFieldSchema>,isBuiltIn: null == isBuiltIn ? _self.isBuiltIn : isBuiltIn // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
