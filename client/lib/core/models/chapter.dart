// ****************************************************************************
//
// @file       chapter.dart
// @brief      章节模型
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chapter.freezed.dart';
part 'chapter.g.dart';

@freezed
class Chapter with _$Chapter {
  const factory Chapter({
    required String id,
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required String title,
    required String content,
    required bool hasImages,
    String? imagePath,
    required int imageCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Chapter;

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);
}
