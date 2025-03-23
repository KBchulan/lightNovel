// ****************************************************************************
//
// @file       read_history.dart
// @brief      阅读历史模型
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:freezed_annotation/freezed_annotation.dart';

part 'read_history.freezed.dart';
part 'read_history.g.dart';

@freezed
class ReadHistory with _$ReadHistory {
  const factory ReadHistory({
    required String id,
    required String deviceId,
    required String novelId,
    required DateTime lastRead,
  }) = _ReadHistory;

  factory ReadHistory.fromJson(Map<String, dynamic> json) =>
      _$ReadHistoryFromJson(json);
}
