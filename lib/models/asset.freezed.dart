// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Asset {

 String get id; String get typeId; String get name; int? get expireAt; int get createdAt; int get updatedAt; bool get isArchived; List<AssetField> get fields; List<Tag> get tags; List<Reminder> get reminders; List<AssetAttachment> get attachments;
/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetCopyWith<Asset> get copyWith => _$AssetCopyWithImpl<Asset>(this as Asset, _$identity);

  /// Serializes this Asset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Asset&&(identical(other.id, id) || other.id == id)&&(identical(other.typeId, typeId) || other.typeId == typeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.expireAt, expireAt) || other.expireAt == expireAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&const DeepCollectionEquality().equals(other.fields, fields)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.reminders, reminders)&&const DeepCollectionEquality().equals(other.attachments, attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,typeId,name,expireAt,createdAt,updatedAt,isArchived,const DeepCollectionEquality().hash(fields),const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(reminders),const DeepCollectionEquality().hash(attachments));

@override
String toString() {
  return 'Asset(id: $id, typeId: $typeId, name: $name, expireAt: $expireAt, createdAt: $createdAt, updatedAt: $updatedAt, isArchived: $isArchived, fields: $fields, tags: $tags, reminders: $reminders, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class $AssetCopyWith<$Res>  {
  factory $AssetCopyWith(Asset value, $Res Function(Asset) _then) = _$AssetCopyWithImpl;
@useResult
$Res call({
 String id, String typeId, String name, int? expireAt, int createdAt, int updatedAt, bool isArchived, List<AssetField> fields, List<Tag> tags, List<Reminder> reminders, List<AssetAttachment> attachments
});




}
/// @nodoc
class _$AssetCopyWithImpl<$Res>
    implements $AssetCopyWith<$Res> {
  _$AssetCopyWithImpl(this._self, this._then);

  final Asset _self;
  final $Res Function(Asset) _then;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? typeId = null,Object? name = null,Object? expireAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isArchived = null,Object? fields = null,Object? tags = null,Object? reminders = null,Object? attachments = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,typeId: null == typeId ? _self.typeId : typeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,expireAt: freezed == expireAt ? _self.expireAt : expireAt // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<AssetField>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<Tag>,reminders: null == reminders ? _self.reminders : reminders // ignore: cast_nullable_to_non_nullable
as List<Reminder>,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<AssetAttachment>,
  ));
}

}


/// Adds pattern-matching-related methods to [Asset].
extension AssetPatterns on Asset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Asset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Asset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Asset value)  $default,){
final _that = this;
switch (_that) {
case _Asset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Asset value)?  $default,){
final _that = this;
switch (_that) {
case _Asset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String typeId,  String name,  int? expireAt,  int createdAt,  int updatedAt,  bool isArchived,  List<AssetField> fields,  List<Tag> tags,  List<Reminder> reminders,  List<AssetAttachment> attachments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Asset() when $default != null:
return $default(_that.id,_that.typeId,_that.name,_that.expireAt,_that.createdAt,_that.updatedAt,_that.isArchived,_that.fields,_that.tags,_that.reminders,_that.attachments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String typeId,  String name,  int? expireAt,  int createdAt,  int updatedAt,  bool isArchived,  List<AssetField> fields,  List<Tag> tags,  List<Reminder> reminders,  List<AssetAttachment> attachments)  $default,) {final _that = this;
switch (_that) {
case _Asset():
return $default(_that.id,_that.typeId,_that.name,_that.expireAt,_that.createdAt,_that.updatedAt,_that.isArchived,_that.fields,_that.tags,_that.reminders,_that.attachments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String typeId,  String name,  int? expireAt,  int createdAt,  int updatedAt,  bool isArchived,  List<AssetField> fields,  List<Tag> tags,  List<Reminder> reminders,  List<AssetAttachment> attachments)?  $default,) {final _that = this;
switch (_that) {
case _Asset() when $default != null:
return $default(_that.id,_that.typeId,_that.name,_that.expireAt,_that.createdAt,_that.updatedAt,_that.isArchived,_that.fields,_that.tags,_that.reminders,_that.attachments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Asset implements Asset {
  const _Asset({required this.id, required this.typeId, required this.name, this.expireAt, required this.createdAt, required this.updatedAt, this.isArchived = false, final  List<AssetField> fields = const [], final  List<Tag> tags = const [], final  List<Reminder> reminders = const [], final  List<AssetAttachment> attachments = const []}): _fields = fields,_tags = tags,_reminders = reminders,_attachments = attachments;
  factory _Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);

@override final  String id;
@override final  String typeId;
@override final  String name;
@override final  int? expireAt;
@override final  int createdAt;
@override final  int updatedAt;
@override@JsonKey() final  bool isArchived;
 final  List<AssetField> _fields;
@override@JsonKey() List<AssetField> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}

 final  List<Tag> _tags;
@override@JsonKey() List<Tag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<Reminder> _reminders;
@override@JsonKey() List<Reminder> get reminders {
  if (_reminders is EqualUnmodifiableListView) return _reminders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminders);
}

 final  List<AssetAttachment> _attachments;
@override@JsonKey() List<AssetAttachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}


/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetCopyWith<_Asset> get copyWith => __$AssetCopyWithImpl<_Asset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Asset&&(identical(other.id, id) || other.id == id)&&(identical(other.typeId, typeId) || other.typeId == typeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.expireAt, expireAt) || other.expireAt == expireAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&const DeepCollectionEquality().equals(other._fields, _fields)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._reminders, _reminders)&&const DeepCollectionEquality().equals(other._attachments, _attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,typeId,name,expireAt,createdAt,updatedAt,isArchived,const DeepCollectionEquality().hash(_fields),const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_reminders),const DeepCollectionEquality().hash(_attachments));

@override
String toString() {
  return 'Asset(id: $id, typeId: $typeId, name: $name, expireAt: $expireAt, createdAt: $createdAt, updatedAt: $updatedAt, isArchived: $isArchived, fields: $fields, tags: $tags, reminders: $reminders, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class _$AssetCopyWith<$Res> implements $AssetCopyWith<$Res> {
  factory _$AssetCopyWith(_Asset value, $Res Function(_Asset) _then) = __$AssetCopyWithImpl;
@override @useResult
$Res call({
 String id, String typeId, String name, int? expireAt, int createdAt, int updatedAt, bool isArchived, List<AssetField> fields, List<Tag> tags, List<Reminder> reminders, List<AssetAttachment> attachments
});




}
/// @nodoc
class __$AssetCopyWithImpl<$Res>
    implements _$AssetCopyWith<$Res> {
  __$AssetCopyWithImpl(this._self, this._then);

  final _Asset _self;
  final $Res Function(_Asset) _then;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? typeId = null,Object? name = null,Object? expireAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isArchived = null,Object? fields = null,Object? tags = null,Object? reminders = null,Object? attachments = null,}) {
  return _then(_Asset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,typeId: null == typeId ? _self.typeId : typeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,expireAt: freezed == expireAt ? _self.expireAt : expireAt // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<AssetField>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<Tag>,reminders: null == reminders ? _self._reminders : reminders // ignore: cast_nullable_to_non_nullable
as List<Reminder>,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<AssetAttachment>,
  ));
}


}

// dart format on
