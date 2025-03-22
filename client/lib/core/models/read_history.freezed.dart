// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'read_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ReadHistory _$ReadHistoryFromJson(Map<String, dynamic> json) {
  return _ReadHistory.fromJson(json);
}

/// @nodoc
mixin _$ReadHistory {
  String get id => throw _privateConstructorUsedError;
  String get deviceId => throw _privateConstructorUsedError;
  String get novelId => throw _privateConstructorUsedError;
  DateTime get lastRead => throw _privateConstructorUsedError;

  /// Serializes this ReadHistory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReadHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReadHistoryCopyWith<ReadHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReadHistoryCopyWith<$Res> {
  factory $ReadHistoryCopyWith(
          ReadHistory value, $Res Function(ReadHistory) then) =
      _$ReadHistoryCopyWithImpl<$Res, ReadHistory>;
  @useResult
  $Res call({String id, String deviceId, String novelId, DateTime lastRead});
}

/// @nodoc
class _$ReadHistoryCopyWithImpl<$Res, $Val extends ReadHistory>
    implements $ReadHistoryCopyWith<$Res> {
  _$ReadHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReadHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = null,
    Object? novelId = null,
    Object? lastRead = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      novelId: null == novelId
          ? _value.novelId
          : novelId // ignore: cast_nullable_to_non_nullable
              as String,
      lastRead: null == lastRead
          ? _value.lastRead
          : lastRead // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReadHistoryImplCopyWith<$Res>
    implements $ReadHistoryCopyWith<$Res> {
  factory _$$ReadHistoryImplCopyWith(
          _$ReadHistoryImpl value, $Res Function(_$ReadHistoryImpl) then) =
      __$$ReadHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String deviceId, String novelId, DateTime lastRead});
}

/// @nodoc
class __$$ReadHistoryImplCopyWithImpl<$Res>
    extends _$ReadHistoryCopyWithImpl<$Res, _$ReadHistoryImpl>
    implements _$$ReadHistoryImplCopyWith<$Res> {
  __$$ReadHistoryImplCopyWithImpl(
      _$ReadHistoryImpl _value, $Res Function(_$ReadHistoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReadHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = null,
    Object? novelId = null,
    Object? lastRead = null,
  }) {
    return _then(_$ReadHistoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      novelId: null == novelId
          ? _value.novelId
          : novelId // ignore: cast_nullable_to_non_nullable
              as String,
      lastRead: null == lastRead
          ? _value.lastRead
          : lastRead // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReadHistoryImpl implements _ReadHistory {
  const _$ReadHistoryImpl(
      {required this.id,
      required this.deviceId,
      required this.novelId,
      required this.lastRead});

  factory _$ReadHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReadHistoryImplFromJson(json);

  @override
  final String id;
  @override
  final String deviceId;
  @override
  final String novelId;
  @override
  final DateTime lastRead;

  @override
  String toString() {
    return 'ReadHistory(id: $id, deviceId: $deviceId, novelId: $novelId, lastRead: $lastRead)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadHistoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.novelId, novelId) || other.novelId == novelId) &&
            (identical(other.lastRead, lastRead) ||
                other.lastRead == lastRead));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, deviceId, novelId, lastRead);

  /// Create a copy of ReadHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReadHistoryImplCopyWith<_$ReadHistoryImpl> get copyWith =>
      __$$ReadHistoryImplCopyWithImpl<_$ReadHistoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReadHistoryImplToJson(
      this,
    );
  }
}

abstract class _ReadHistory implements ReadHistory {
  const factory _ReadHistory(
      {required final String id,
      required final String deviceId,
      required final String novelId,
      required final DateTime lastRead}) = _$ReadHistoryImpl;

  factory _ReadHistory.fromJson(Map<String, dynamic> json) =
      _$ReadHistoryImpl.fromJson;

  @override
  String get id;
  @override
  String get deviceId;
  @override
  String get novelId;
  @override
  DateTime get lastRead;

  /// Create a copy of ReadHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReadHistoryImplCopyWith<_$ReadHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
