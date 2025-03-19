// ****************************************************************************
//
// @file       novel.dart
// @brief      小说模型
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:freezed_annotation/freezed_annotation.dart';

part 'novel.freezed.dart';
part 'novel.g.dart';

@freezed
class Novel with _$Novel {
  const factory Novel({
    required String id,
    required String title,
    @Default('') String author,
    @Default('') String description,
    @Default('') String cover,
    @Default(0) int volumeCount,
    @Default([]) List<String> tags,
    @Default('') String status, // 连载中、已完结
    @Default(0) int readCount, // 阅读量
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Novel;

  factory Novel.fromJson(Map<String, dynamic> json) => _$NovelFromJson(json);
}
