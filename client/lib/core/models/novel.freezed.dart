// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'novel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Novel _$NovelFromJson(Map<String, dynamic> json) {
  return _Novel.fromJson(json);
}

/// @nodoc
mixin _$Novel {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get author => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get cover => throw _privateConstructorUsedError;
  int get volumeCount => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError; // 连载中、已完结
  int get readCount => throw _privateConstructorUsedError; // 阅读量
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Novel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Novel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NovelCopyWith<Novel> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NovelCopyWith<$Res> {
  factory $NovelCopyWith(Novel value, $Res Function(Novel) then) =
      _$NovelCopyWithImpl<$Res, Novel>;
  @useResult
  $Res call(
      {String id,
      String title,
      String author,
      String description,
      String cover,
      int volumeCount,
      List<String> tags,
      String status,
      int readCount,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$NovelCopyWithImpl<$Res, $Val extends Novel>
    implements $NovelCopyWith<$Res> {
  _$NovelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Novel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? author = null,
    Object? description = null,
    Object? cover = null,
    Object? volumeCount = null,
    Object? tags = null,
    Object? status = null,
    Object? readCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      cover: null == cover
          ? _value.cover
          : cover // ignore: cast_nullable_to_non_nullable
              as String,
      volumeCount: null == volumeCount
          ? _value.volumeCount
          : volumeCount // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      readCount: null == readCount
          ? _value.readCount
          : readCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NovelImplCopyWith<$Res> implements $NovelCopyWith<$Res> {
  factory _$$NovelImplCopyWith(
          _$NovelImpl value, $Res Function(_$NovelImpl) then) =
      __$$NovelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String author,
      String description,
      String cover,
      int volumeCount,
      List<String> tags,
      String status,
      int readCount,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$NovelImplCopyWithImpl<$Res>
    extends _$NovelCopyWithImpl<$Res, _$NovelImpl>
    implements _$$NovelImplCopyWith<$Res> {
  __$$NovelImplCopyWithImpl(
      _$NovelImpl _value, $Res Function(_$NovelImpl) _then)
      : super(_value, _then);

  /// Create a copy of Novel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? author = null,
    Object? description = null,
    Object? cover = null,
    Object? volumeCount = null,
    Object? tags = null,
    Object? status = null,
    Object? readCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$NovelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      cover: null == cover
          ? _value.cover
          : cover // ignore: cast_nullable_to_non_nullable
              as String,
      volumeCount: null == volumeCount
          ? _value.volumeCount
          : volumeCount // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      readCount: null == readCount
          ? _value.readCount
          : readCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NovelImpl implements _Novel {
  const _$NovelImpl(
      {required this.id,
      required this.title,
      this.author = '',
      this.description = '',
      this.cover = '',
      this.volumeCount = 0,
      final List<String> tags = const [],
      this.status = '',
      this.readCount = 0,
      required this.createdAt,
      required this.updatedAt})
      : _tags = tags;

  factory _$NovelImpl.fromJson(Map<String, dynamic> json) =>
      _$$NovelImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey()
  final String author;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey()
  final String cover;
  @override
  @JsonKey()
  final int volumeCount;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final String status;
// 连载中、已完结
  @override
  @JsonKey()
  final int readCount;
// 阅读量
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Novel(id: $id, title: $title, author: $author, description: $description, cover: $cover, volumeCount: $volumeCount, tags: $tags, status: $status, readCount: $readCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NovelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.cover, cover) || other.cover == cover) &&
            (identical(other.volumeCount, volumeCount) ||
                other.volumeCount == volumeCount) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.readCount, readCount) ||
                other.readCount == readCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      author,
      description,
      cover,
      volumeCount,
      const DeepCollectionEquality().hash(_tags),
      status,
      readCount,
      createdAt,
      updatedAt);

  /// Create a copy of Novel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NovelImplCopyWith<_$NovelImpl> get copyWith =>
      __$$NovelImplCopyWithImpl<_$NovelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NovelImplToJson(
      this,
    );
  }
}

abstract class _Novel implements Novel {
  const factory _Novel(
      {required final String id,
      required final String title,
      final String author,
      final String description,
      final String cover,
      final int volumeCount,
      final List<String> tags,
      final String status,
      final int readCount,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$NovelImpl;

  factory _Novel.fromJson(Map<String, dynamic> json) = _$NovelImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get author;
  @override
  String get description;
  @override
  String get cover;
  @override
  int get volumeCount;
  @override
  List<String> get tags;
  @override
  String get status; // 连载中、已完结
  @override
  int get readCount; // 阅读量
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Novel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NovelImplCopyWith<_$NovelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
