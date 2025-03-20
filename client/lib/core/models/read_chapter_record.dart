// ****************************************************************************
//
// @file       read_chapter_record.dart
// @brief      已读章节记录模型
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:freezed_annotation/freezed_annotation.dart';

part 'read_chapter_record.freezed.dart';
part 'read_chapter_record.g.dart';

@freezed
class ReadChapterRecord with _$ReadChapterRecord {
  const factory ReadChapterRecord({
    required String id,
    required String deviceId,
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required int lastPosition,
    required int readCount,
    required bool isComplete,
    required DateTime firstReadAt,
    required DateTime lastReadAt,
  }) = _ReadChapterRecord;

  factory ReadChapterRecord.fromJson(Map<String, dynamic> json) =>
      _$ReadChapterRecordFromJson(json);
} 