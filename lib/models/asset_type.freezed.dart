// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AssetTypeFieldSchema _$AssetTypeFieldSchemaFromJson(Map<String, dynamic> json) {
  return _AssetTypeFieldSchema.fromJson(json);
}

/// @nodoc
mixin _$AssetTypeFieldSchema {
  String get key => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // 'text', 'password', 'date', 'number'
  bool get isEncrypted => throw _privateConstructorUsedError;
  bool get isRequired => throw _privateConstructorUsedError;

  /// Serializes this AssetTypeFieldSchema to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AssetTypeFieldSchema
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssetTypeFieldSchemaCopyWith<AssetTypeFieldSchema> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssetTypeFieldSchemaCopyWith<$Res> {
  factory $AssetTypeFieldSchemaCopyWith(
    AssetTypeFieldSchema value,
    $Res Function(AssetTypeFieldSchema) then,
  ) = _$AssetTypeFieldSchemaCopyWithImpl<$Res, AssetTypeFieldSchema>;
  @useResult
  $Res call({
    String key,
    String label,
    String type,
    bool isEncrypted,
    bool isRequired,
  });
}

/// @nodoc
class _$AssetTypeFieldSchemaCopyWithImpl<
  $Res,
  $Val extends AssetTypeFieldSchema
>
    implements $AssetTypeFieldSchemaCopyWith<$Res> {
  _$AssetTypeFieldSchemaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AssetTypeFieldSchema
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? label = null,
    Object? type = null,
    Object? isEncrypted = null,
    Object? isRequired = null,
  }) {
    return _then(
      _value.copyWith(
            key: null == key
                ? _value.key
                : key // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            isEncrypted: null == isEncrypted
                ? _value.isEncrypted
                : isEncrypted // ignore: cast_nullable_to_non_nullable
                      as bool,
            isRequired: null == isRequired
                ? _value.isRequired
                : isRequired // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AssetTypeFieldSchemaImplCopyWith<$Res>
    implements $AssetTypeFieldSchemaCopyWith<$Res> {
  factory _$$AssetTypeFieldSchemaImplCopyWith(
    _$AssetTypeFieldSchemaImpl value,
    $Res Function(_$AssetTypeFieldSchemaImpl) then,
  ) = __$$AssetTypeFieldSchemaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String key,
    String label,
    String type,
    bool isEncrypted,
    bool isRequired,
  });
}

/// @nodoc
class __$$AssetTypeFieldSchemaImplCopyWithImpl<$Res>
    extends _$AssetTypeFieldSchemaCopyWithImpl<$Res, _$AssetTypeFieldSchemaImpl>
    implements _$$AssetTypeFieldSchemaImplCopyWith<$Res> {
  __$$AssetTypeFieldSchemaImplCopyWithImpl(
    _$AssetTypeFieldSchemaImpl _value,
    $Res Function(_$AssetTypeFieldSchemaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AssetTypeFieldSchema
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? label = null,
    Object? type = null,
    Object? isEncrypted = null,
    Object? isRequired = null,
  }) {
    return _then(
      _$AssetTypeFieldSchemaImpl(
        key: null == key
            ? _value.key
            : key // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        isEncrypted: null == isEncrypted
            ? _value.isEncrypted
            : isEncrypted // ignore: cast_nullable_to_non_nullable
                  as bool,
        isRequired: null == isRequired
            ? _value.isRequired
            : isRequired // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AssetTypeFieldSchemaImpl implements _AssetTypeFieldSchema {
  const _$AssetTypeFieldSchemaImpl({
    required this.key,
    required this.label,
    required this.type,
    this.isEncrypted = false,
    this.isRequired = false,
  });

  factory _$AssetTypeFieldSchemaImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssetTypeFieldSchemaImplFromJson(json);

  @override
  final String key;
  @override
  final String label;
  @override
  final String type;
  // 'text', 'password', 'date', 'number'
  @override
  @JsonKey()
  final bool isEncrypted;
  @override
  @JsonKey()
  final bool isRequired;

  @override
  String toString() {
    return 'AssetTypeFieldSchema(key: $key, label: $label, type: $type, isEncrypted: $isEncrypted, isRequired: $isRequired)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssetTypeFieldSchemaImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isEncrypted, isEncrypted) ||
                other.isEncrypted == isEncrypted) &&
            (identical(other.isRequired, isRequired) ||
                other.isRequired == isRequired));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, key, label, type, isEncrypted, isRequired);

  /// Create a copy of AssetTypeFieldSchema
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssetTypeFieldSchemaImplCopyWith<_$AssetTypeFieldSchemaImpl>
  get copyWith =>
      __$$AssetTypeFieldSchemaImplCopyWithImpl<_$AssetTypeFieldSchemaImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AssetTypeFieldSchemaImplToJson(this);
  }
}

abstract class _AssetTypeFieldSchema implements AssetTypeFieldSchema {
  const factory _AssetTypeFieldSchema({
    required final String key,
    required final String label,
    required final String type,
    final bool isEncrypted,
    final bool isRequired,
  }) = _$AssetTypeFieldSchemaImpl;

  factory _AssetTypeFieldSchema.fromJson(Map<String, dynamic> json) =
      _$AssetTypeFieldSchemaImpl.fromJson;

  @override
  String get key;
  @override
  String get label;
  @override
  String get type; // 'text', 'password', 'date', 'number'
  @override
  bool get isEncrypted;
  @override
  bool get isRequired;

  /// Create a copy of AssetTypeFieldSchema
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssetTypeFieldSchemaImplCopyWith<_$AssetTypeFieldSchemaImpl>
  get copyWith => throw _privateConstructorUsedError;
}

AssetType _$AssetTypeFromJson(Map<String, dynamic> json) {
  return _AssetType.fromJson(json);
}

/// @nodoc
mixin _$AssetType {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  List<AssetTypeFieldSchema> get fieldSchema =>
      throw _privateConstructorUsedError;
  bool get isBuiltIn => throw _privateConstructorUsedError;

  /// Serializes this AssetType to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AssetType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssetTypeCopyWith<AssetType> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssetTypeCopyWith<$Res> {
  factory $AssetTypeCopyWith(AssetType value, $Res Function(AssetType) then) =
      _$AssetTypeCopyWithImpl<$Res, AssetType>;
  @useResult
  $Res call({
    String id,
    String name,
    String icon,
    List<AssetTypeFieldSchema> fieldSchema,
    bool isBuiltIn,
  });
}

/// @nodoc
class _$AssetTypeCopyWithImpl<$Res, $Val extends AssetType>
    implements $AssetTypeCopyWith<$Res> {
  _$AssetTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AssetType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? icon = null,
    Object? fieldSchema = null,
    Object? isBuiltIn = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            icon: null == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                      as String,
            fieldSchema: null == fieldSchema
                ? _value.fieldSchema
                : fieldSchema // ignore: cast_nullable_to_non_nullable
                      as List<AssetTypeFieldSchema>,
            isBuiltIn: null == isBuiltIn
                ? _value.isBuiltIn
                : isBuiltIn // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AssetTypeImplCopyWith<$Res>
    implements $AssetTypeCopyWith<$Res> {
  factory _$$AssetTypeImplCopyWith(
    _$AssetTypeImpl value,
    $Res Function(_$AssetTypeImpl) then,
  ) = __$$AssetTypeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String icon,
    List<AssetTypeFieldSchema> fieldSchema,
    bool isBuiltIn,
  });
}

/// @nodoc
class __$$AssetTypeImplCopyWithImpl<$Res>
    extends _$AssetTypeCopyWithImpl<$Res, _$AssetTypeImpl>
    implements _$$AssetTypeImplCopyWith<$Res> {
  __$$AssetTypeImplCopyWithImpl(
    _$AssetTypeImpl _value,
    $Res Function(_$AssetTypeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AssetType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? icon = null,
    Object? fieldSchema = null,
    Object? isBuiltIn = null,
  }) {
    return _then(
      _$AssetTypeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        icon: null == icon
            ? _value.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String,
        fieldSchema: null == fieldSchema
            ? _value._fieldSchema
            : fieldSchema // ignore: cast_nullable_to_non_nullable
                  as List<AssetTypeFieldSchema>,
        isBuiltIn: null == isBuiltIn
            ? _value.isBuiltIn
            : isBuiltIn // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AssetTypeImpl implements _AssetType {
  const _$AssetTypeImpl({
    required this.id,
    required this.name,
    required this.icon,
    final List<AssetTypeFieldSchema> fieldSchema = const [],
    this.isBuiltIn = false,
  }) : _fieldSchema = fieldSchema;

  factory _$AssetTypeImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssetTypeImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String icon;
  final List<AssetTypeFieldSchema> _fieldSchema;
  @override
  @JsonKey()
  List<AssetTypeFieldSchema> get fieldSchema {
    if (_fieldSchema is EqualUnmodifiableListView) return _fieldSchema;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fieldSchema);
  }

  @override
  @JsonKey()
  final bool isBuiltIn;

  @override
  String toString() {
    return 'AssetType(id: $id, name: $name, icon: $icon, fieldSchema: $fieldSchema, isBuiltIn: $isBuiltIn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssetTypeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            const DeepCollectionEquality().equals(
              other._fieldSchema,
              _fieldSchema,
            ) &&
            (identical(other.isBuiltIn, isBuiltIn) ||
                other.isBuiltIn == isBuiltIn));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    icon,
    const DeepCollectionEquality().hash(_fieldSchema),
    isBuiltIn,
  );

  /// Create a copy of AssetType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssetTypeImplCopyWith<_$AssetTypeImpl> get copyWith =>
      __$$AssetTypeImplCopyWithImpl<_$AssetTypeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AssetTypeImplToJson(this);
  }
}

abstract class _AssetType implements AssetType {
  const factory _AssetType({
    required final String id,
    required final String name,
    required final String icon,
    final List<AssetTypeFieldSchema> fieldSchema,
    final bool isBuiltIn,
  }) = _$AssetTypeImpl;

  factory _AssetType.fromJson(Map<String, dynamic> json) =
      _$AssetTypeImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get icon;
  @override
  List<AssetTypeFieldSchema> get fieldSchema;
  @override
  bool get isBuiltIn;

  /// Create a copy of AssetType
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssetTypeImplCopyWith<_$AssetTypeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
