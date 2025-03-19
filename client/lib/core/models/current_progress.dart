// ****************************************************************************
//
// @file       current_progress.dart
// @brief      当前阅读进度模型
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:freezed_annotation/freezed_annotation.dart';

part 'current_progress.freezed.dart';
part 'current_progress.g.dart';

@freezed
class CurrentProgress with _$CurrentProgress {
  const factory CurrentProgress({
    required int volumeNumber,
    required int chapterNumber,
    required int position,
    required DateTime lastReadAt,
  }) = _CurrentProgress;

  factory CurrentProgress.fromJson(Map<String, dynamic> json) =>
      _$CurrentProgressFromJson(json);
}
