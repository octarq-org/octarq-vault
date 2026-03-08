// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Asset _$AssetFromJson(Map<String, dynamic> json) {
  return _Asset.fromJson(json);
}

/// @nodoc
mixin _$Asset {
  String get id => throw _privateConstructorUsedError;
  String get typeId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int? get expireAt => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  int get updatedAt => throw _privateConstructorUsedError;
  bool get isArchived => throw _privateConstructorUsedError;
  List<AssetField> get fields => throw _privateConstructorUsedError;
  List<Tag> get tags => throw _privateConstructorUsedError;
  List<Reminder> get reminders => throw _privateConstructorUsedError;

  /// Serializes this Asset to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Asset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssetCopyWith<Asset> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssetCopyWith<$Res> {
  factory $AssetCopyWith(Asset value, $Res Function(Asset) then) =
      _$AssetCopyWithImpl<$Res, Asset>;
  @useResult
  $Res call({
    String id,
    String typeId,
    String name,
    int? expireAt,
    int createdAt,
    int updatedAt,
    bool isArchived,
    List<AssetField> fields,
    List<Tag> tags,
    List<Reminder> reminders,
  });
}

/// @nodoc
class _$AssetCopyWithImpl<$Res, $Val extends Asset>
    implements $AssetCopyWith<$Res> {
  _$AssetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Asset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? typeId = null,
    Object? name = null,
    Object? expireAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isArchived = null,
    Object? fields = null,
    Object? tags = null,
    Object? reminders = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            typeId: null == typeId
                ? _value.typeId
                : typeId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            expireAt: freezed == expireAt
                ? _value.expireAt
                : expireAt // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as int,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as int,
            isArchived: null == isArchived
                ? _value.isArchived
                : isArchived // ignore: cast_nullable_to_non_nullable
                      as bool,
            fields: null == fields
                ? _value.fields
                : fields // ignore: cast_nullable_to_non_nullable
                      as List<AssetField>,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<Tag>,
            reminders: null == reminders
                ? _value.reminders
                : reminders // ignore: cast_nullable_to_non_nullable
                      as List<Reminder>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AssetImplCopyWith<$Res> implements $AssetCopyWith<$Res> {
  factory _$$AssetImplCopyWith(
    _$AssetImpl value,
    $Res Function(_$AssetImpl) then,
  ) = __$$AssetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String typeId,
    String name,
    int? expireAt,
    int createdAt,
    int updatedAt,
    bool isArchived,
    List<AssetField> fields,
    List<Tag> tags,
    List<Reminder> reminders,
  });
}

/// @nodoc
class __$$AssetImplCopyWithImpl<$Res>
    extends _$AssetCopyWithImpl<$Res, _$AssetImpl>
    implements _$$AssetImplCopyWith<$Res> {
  __$$AssetImplCopyWithImpl(
    _$AssetImpl _value,
    $Res Function(_$AssetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Asset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? typeId = null,
    Object? name = null,
    Object? expireAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isArchived = null,
    Object? fields = null,
    Object? tags = null,
    Object? reminders = null,
  }) {
    return _then(
      _$AssetImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        typeId: null == typeId
            ? _value.typeId
            : typeId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        expireAt: freezed == expireAt
            ? _value.expireAt
            : expireAt // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as int,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as int,
        isArchived: null == isArchived
            ? _value.isArchived
            : isArchived // ignore: cast_nullable_to_non_nullable
                  as bool,
        fields: null == fields
            ? _value._fields
            : fields // ignore: cast_nullable_to_non_nullable
                  as List<AssetField>,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<Tag>,
        reminders: null == reminders
            ? _value._reminders
            : reminders // ignore: cast_nullable_to_non_nullable
                  as List<Reminder>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AssetImpl implements _Asset {
  const _$AssetImpl({
    required this.id,
    required this.typeId,
    required this.name,
    this.expireAt,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    final List<AssetField> fields = const [],
    final List<Tag> tags = const [],
    final List<Reminder> reminders = const [],
  }) : _fields = fields,
       _tags = tags,
       _reminders = reminders;

  factory _$AssetImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssetImplFromJson(json);

  @override
  final String id;
  @override
  final String typeId;
  @override
  final String name;
  @override
  final int? expireAt;
  @override
  final int createdAt;
  @override
  final int updatedAt;
  @override
  @JsonKey()
  final bool isArchived;
  final List<AssetField> _fields;
  @override
  @JsonKey()
  List<AssetField> get fields {
    if (_fields is EqualUnmodifiableListView) return _fields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fields);
  }

  final List<Tag> _tags;
  @override
  @JsonKey()
  List<Tag> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<Reminder> _reminders;
  @override
  @JsonKey()
  List<Reminder> get reminders {
    if (_reminders is EqualUnmodifiableListView) return _reminders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reminders);
  }

  @override
  String toString() {
    return 'Asset(id: $id, typeId: $typeId, name: $name, expireAt: $expireAt, createdAt: $createdAt, updatedAt: $updatedAt, isArchived: $isArchived, fields: $fields, tags: $tags, reminders: $reminders)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.typeId, typeId) || other.typeId == typeId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.expireAt, expireAt) ||
                other.expireAt == expireAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived) &&
            const DeepCollectionEquality().equals(other._fields, _fields) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(
              other._reminders,
              _reminders,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    typeId,
    name,
    expireAt,
    createdAt,
    updatedAt,
    isArchived,
    const DeepCollectionEquality().hash(_fields),
    const DeepCollectionEquality().hash(_tags),
    const DeepCollectionEquality().hash(_reminders),
  );

  /// Create a copy of Asset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssetImplCopyWith<_$AssetImpl> get copyWith =>
      __$$AssetImplCopyWithImpl<_$AssetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AssetImplToJson(this);
  }
}

abstract class _Asset implements Asset {
  const factory _Asset({
    required final String id,
    required final String typeId,
    required final String name,
    final int? expireAt,
    required final int createdAt,
    required final int updatedAt,
    final bool isArchived,
    final List<AssetField> fields,
    final List<Tag> tags,
    final List<Reminder> reminders,
  }) = _$AssetImpl;

  factory _Asset.fromJson(Map<String, dynamic> json) = _$AssetImpl.fromJson;

  @override
  String get id;
  @override
  String get typeId;
  @override
  String get name;
  @override
  int? get expireAt;
  @override
  int get createdAt;
  @override
  int get updatedAt;
  @override
  bool get isArchived;
  @override
  List<AssetField> get fields;
  @override
  List<Tag> get tags;
  @override
  List<Reminder> get reminders;

  /// Create a copy of Asset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssetImplCopyWith<_$AssetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
