import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

/// 评论模型
@freezed
class Comment with _$Comment {
  const factory Comment({
    required String id,
    required String deviceId,
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
} 