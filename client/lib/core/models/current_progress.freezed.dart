// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'current_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CurrentProgress _$CurrentProgressFromJson(Map<String, dynamic> json) {
  return _CurrentProgress.fromJson(json);
}

/// @nodoc
mixin _$CurrentProgress {
  int get volumeNumber => throw _privateConstructorUsedError;
  int get chapterNumber => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
  DateTime get lastReadAt => throw _privateConstructorUsedError;

  /// Serializes this CurrentProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CurrentProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CurrentProgressCopyWith<CurrentProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CurrentProgressCopyWith<$Res> {
  factory $CurrentProgressCopyWith(
          CurrentProgress value, $Res Function(CurrentProgress) then) =
      _$CurrentProgressCopyWithImpl<$Res, CurrentProgress>;
  @useResult
  $Res call(
      {int volumeNumber, int chapterNumber, int position, DateTime lastReadAt});
}

/// @nodoc
class _$CurrentProgressCopyWithImpl<$Res, $Val extends CurrentProgress>
    implements $CurrentProgressCopyWith<$Res> {
  _$CurrentProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CurrentProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volumeNumber = null,
    Object? chapterNumber = null,
    Object? position = null,
    Object? lastReadAt = null,
  }) {
    return _then(_value.copyWith(
      volumeNumber: null == volumeNumber
          ? _value.volumeNumber
          : volumeNumber // ignore: cast_nullable_to_non_nullable
              as int,
      chapterNumber: null == chapterNumber
          ? _value.chapterNumber
          : chapterNumber // ignore: cast_nullable_to_non_nullable
              as int,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      lastReadAt: null == lastReadAt
          ? _value.lastReadAt
          : lastReadAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CurrentProgressImplCopyWith<$Res>
    implements $CurrentProgressCopyWith<$Res> {
  factory _$$CurrentProgressImplCopyWith(_$CurrentProgressImpl value,
          $Res Function(_$CurrentProgressImpl) then) =
      __$$CurrentProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int volumeNumber, int chapterNumber, int position, DateTime lastReadAt});
}

/// @nodoc
class __$$CurrentProgressImplCopyWithImpl<$Res>
    extends _$CurrentProgressCopyWithImpl<$Res, _$CurrentProgressImpl>
    implements _$$CurrentProgressImplCopyWith<$Res> {
  __$$CurrentProgressImplCopyWithImpl(
      _$CurrentProgressImpl _value, $Res Function(_$CurrentProgressImpl) _then)
      : super(_value, _then);

  /// Create a copy of CurrentProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? volumeNumber = null,
    Object? chapterNumber = null,
    Object? position = null,
    Object? lastReadAt = null,
  }) {
    return _then(_$CurrentProgressImpl(
      volumeNumber: null == volumeNumber
          ? _value.volumeNumber
          : volumeNumber // ignore: cast_nullable_to_non_nullable
              as int,
      chapterNumber: null == chapterNumber
          ? _value.chapterNumber
          : chapterNumber // ignore: cast_nullable_to_non_nullable
              as int,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      lastReadAt: null == lastReadAt
          ? _value.lastReadAt
          : lastReadAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CurrentProgressImpl implements _CurrentProgress {
  const _$CurrentProgressImpl(
      {required this.volumeNumber,
      required this.chapterNumber,
      required this.position,
      required this.lastReadAt});

  factory _$CurrentProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$CurrentProgressImplFromJson(json);

  @override
  final int volumeNumber;
  @override
  final int chapterNumber;
  @override
  final int position;
  @override
  final DateTime lastReadAt;

  @override
  String toString() {
    return 'CurrentProgress(volumeNumber: $volumeNumber, chapterNumber: $chapterNumber, position: $position, lastReadAt: $lastReadAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CurrentProgressImpl &&
            (identical(other.volumeNumber, volumeNumber) ||
                other.volumeNumber == volumeNumber) &&
            (identical(other.chapterNumber, chapterNumber) ||
                other.chapterNumber == chapterNumber) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.lastReadAt, lastReadAt) ||
                other.lastReadAt == lastReadAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, volumeNumber, chapterNumber, position, lastReadAt);

  /// Create a copy of CurrentProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CurrentProgressImplCopyWith<_$CurrentProgressImpl> get copyWith =>
      __$$CurrentProgressImplCopyWithImpl<_$CurrentProgressImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CurrentProgressImplToJson(
      this,
    );
  }
}

abstract class _CurrentProgress implements CurrentProgress {
  const factory _CurrentProgress(
      {required final int volumeNumber,
      required final int chapterNumber,
      required final int position,
      required final DateTime lastReadAt}) = _$CurrentProgressImpl;

  factory _CurrentProgress.fromJson(Map<String, dynamic> json) =
      _$CurrentProgressImpl.fromJson;

  @override
  int get volumeNumber;
  @override
  int get chapterNumber;
  @override
  int get position;
  @override
  DateTime get lastReadAt;

  /// Create a copy of CurrentProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CurrentProgressImplCopyWith<_$CurrentProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
