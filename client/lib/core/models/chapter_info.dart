// ****************************************************************************
//
// @file       chapter_info.dart
// @brief      章节信息模型
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chapter_info.freezed.dart';
part 'chapter_info.g.dart';

@freezed
class ChapterInfo with _$ChapterInfo {
  const factory ChapterInfo({
    required String id,
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ChapterInfo;

  factory ChapterInfo.fromJson(Map<String, dynamic> json) =>
      _$ChapterInfoFromJson(json);
}
