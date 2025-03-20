// ****************************************************************************
//
// @file       reading_stat.dart
// @brief      阅读统计模型
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_stat.freezed.dart';
part 'reading_stat.g.dart';

@freezed
class ReadingStat with _$ReadingStat {
  const factory ReadingStat({
    required String id,
    required String deviceId,
    required String novelId,
    required int chapterRead,
    required int totalChapters,
    required int completeCount,
    required int totalReadTime,
    required double readProgress,
    required List<String> readDays,
    required DateTime lastActiveDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ReadingStat;

  factory ReadingStat.fromJson(Map<String, dynamic> json) =>
      _$ReadingStatFromJson(json);
} 