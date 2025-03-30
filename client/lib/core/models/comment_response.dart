import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_response.freezed.dart';
part 'comment_response.g.dart';

/// 评论响应模型（包含用户信息）
@freezed
class CommentResponse with _$CommentResponse {
  const factory CommentResponse({
    required String id,
    required String userId,
    required String userName,
    required String userAvatar,
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required String content,
    required DateTime createdAt,
  }) = _CommentResponse;

  factory CommentResponse.fromJson(Map<String, dynamic> json) => _$CommentResponseFromJson(json);
} 