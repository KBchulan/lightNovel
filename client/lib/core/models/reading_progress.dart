// ****************************************************************************
//
// @file       reading_progress.dart
// @brief      阅读进度模型
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:freezed_annotation/freezed_annotation.dart';
import 'current_progress.dart';

part 'reading_progress.freezed.dart';
part 'reading_progress.g.dart';

@freezed
class ReadingProgress with _$ReadingProgress {
  const factory ReadingProgress({
    required String id,
    required String deviceId,
    required String novelId,
    required CurrentProgress currentProgress,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ReadingProgress;

  factory ReadingProgress.fromJson(Map<String, dynamic> json) =>
      _$ReadingProgressFromJson(json);
}
