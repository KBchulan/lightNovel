// ****************************************************************************
//
// @file       bookmark.dart
// @brief      书签模型
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark.freezed.dart';
part 'bookmark.g.dart';

@freezed
class Bookmark with _$Bookmark {
  const factory Bookmark({
    required String id,
    required String deviceId,
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required int position,
    required String note,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Bookmark;

  factory Bookmark.fromJson(Map<String, dynamic> json) =>
      _$BookmarkFromJson(json);
}
