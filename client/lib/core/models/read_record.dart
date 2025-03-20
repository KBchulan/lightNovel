// ****************************************************************************
//
// @file       read_record.dart
// @brief      阅读记录模型
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:freezed_annotation/freezed_annotation.dart';

part 'read_record.freezed.dart';
part 'read_record.g.dart';

@freezed
class ReadRecord with _$ReadRecord {
  const factory ReadRecord({
    required String id,
    required String deviceId,
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required int startPosition,
    required int endPosition,
    required int readDuration,
    required bool isComplete,
    required String source,
    required DateTime readAt,
  }) = _ReadRecord;

  factory ReadRecord.fromJson(Map<String, dynamic> json) =>
      _$ReadRecordFromJson(json);
} 