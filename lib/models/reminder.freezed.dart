// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Reminder _$ReminderFromJson(Map<String, dynamic> json) {
  return _Reminder.fromJson(json);
}

/// @nodoc
mixin _$Reminder {
  String get id => throw _privateConstructorUsedError;
  String get assetId => throw _privateConstructorUsedError;
  String get triggerType =>
      throw _privateConstructorUsedError; // e.g. 'expiration', 'recurring'
  int get offsetDays => throw _privateConstructorUsedError;
  List<String> get channels => throw _privateConstructorUsedError;
  bool get isRecurring => throw _privateConstructorUsedError;

  /// Serializes this Reminder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Reminder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReminderCopyWith<Reminder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReminderCopyWith<$Res> {
  factory $ReminderCopyWith(Reminder value, $Res Function(Reminder) then) =
      _$ReminderCopyWithImpl<$Res, Reminder>;
  @useResult
  $Res call({
    String id,
    String assetId,
    String triggerType,
    int offsetDays,
    List<String> channels,
    bool isRecurring,
  });
}

/// @nodoc
class _$ReminderCopyWithImpl<$Res, $Val extends Reminder>
    implements $ReminderCopyWith<$Res> {
  _$ReminderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Reminder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? assetId = null,
    Object? triggerType = null,
    Object? offsetDays = null,
    Object? channels = null,
    Object? isRecurring = null,
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
            triggerType: null == triggerType
                ? _value.triggerType
                : triggerType // ignore: cast_nullable_to_non_nullable
                      as String,
            offsetDays: null == offsetDays
                ? _value.offsetDays
                : offsetDays // ignore: cast_nullable_to_non_nullable
                      as int,
            channels: null == channels
                ? _value.channels
                : channels // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isRecurring: null == isRecurring
                ? _value.isRecurring
                : isRecurring // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReminderImplCopyWith<$Res>
    implements $ReminderCopyWith<$Res> {
  factory _$$ReminderImplCopyWith(
    _$ReminderImpl value,
    $Res Function(_$ReminderImpl) then,
  ) = __$$ReminderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String assetId,
    String triggerType,
    int offsetDays,
    List<String> channels,
    bool isRecurring,
  });
}

/// @nodoc
class __$$ReminderImplCopyWithImpl<$Res>
    extends _$ReminderCopyWithImpl<$Res, _$ReminderImpl>
    implements _$$ReminderImplCopyWith<$Res> {
  __$$ReminderImplCopyWithImpl(
    _$ReminderImpl _value,
    $Res Function(_$ReminderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Reminder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? assetId = null,
    Object? triggerType = null,
    Object? offsetDays = null,
    Object? channels = null,
    Object? isRecurring = null,
  }) {
    return _then(
      _$ReminderImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        assetId: null == assetId
            ? _value.assetId
            : assetId // ignore: cast_nullable_to_non_nullable
                  as String,
        triggerType: null == triggerType
            ? _value.triggerType
            : triggerType // ignore: cast_nullable_to_non_nullable
                  as String,
        offsetDays: null == offsetDays
            ? _value.offsetDays
            : offsetDays // ignore: cast_nullable_to_non_nullable
                  as int,
        channels: null == channels
            ? _value._channels
            : channels // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isRecurring: null == isRecurring
            ? _value.isRecurring
            : isRecurring // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReminderImpl implements _Reminder {
  const _$ReminderImpl({
    required this.id,
    required this.assetId,
    required this.triggerType,
    required this.offsetDays,
    final List<String> channels = const [],
    this.isRecurring = false,
  }) : _channels = channels;

  factory _$ReminderImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReminderImplFromJson(json);

  @override
  final String id;
  @override
  final String assetId;
  @override
  final String triggerType;
  // e.g. 'expiration', 'recurring'
  @override
  final int offsetDays;
  final List<String> _channels;
  @override
  @JsonKey()
  List<String> get channels {
    if (_channels is EqualUnmodifiableListView) return _channels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_channels);
  }

  @override
  @JsonKey()
  final bool isRecurring;

  @override
  String toString() {
    return 'Reminder(id: $id, assetId: $assetId, triggerType: $triggerType, offsetDays: $offsetDays, channels: $channels, isRecurring: $isRecurring)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReminderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.assetId, assetId) || other.assetId == assetId) &&
            (identical(other.triggerType, triggerType) ||
                other.triggerType == triggerType) &&
            (identical(other.offsetDays, offsetDays) ||
                other.offsetDays == offsetDays) &&
            const DeepCollectionEquality().equals(other._channels, _channels) &&
            (identical(other.isRecurring, isRecurring) ||
                other.isRecurring == isRecurring));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    assetId,
    triggerType,
    offsetDays,
    const DeepCollectionEquality().hash(_channels),
    isRecurring,
  );

  /// Create a copy of Reminder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReminderImplCopyWith<_$ReminderImpl> get copyWith =>
      __$$ReminderImplCopyWithImpl<_$ReminderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReminderImplToJson(this);
  }
}

abstract class _Reminder implements Reminder {
  const factory _Reminder({
    required final String id,
    required final String assetId,
    required final String triggerType,
    required final int offsetDays,
    final List<String> channels,
    final bool isRecurring,
  }) = _$ReminderImpl;

  factory _Reminder.fromJson(Map<String, dynamic> json) =
      _$ReminderImpl.fromJson;

  @override
  String get id;
  @override
  String get assetId;
  @override
  String get triggerType; // e.g. 'expiration', 'recurring'
  @override
  int get offsetDays;
  @override
  List<String> get channels;
  @override
  bool get isRecurring;

  /// Create a copy of Reminder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReminderImplCopyWith<_$ReminderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
