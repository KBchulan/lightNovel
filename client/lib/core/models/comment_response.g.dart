// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentResponseImpl _$$CommentResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$CommentResponseImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      novelId: json['novelId'] as String,
      volumeNumber: (json['volumeNumber'] as num).toInt(),
      chapterNumber: (json['chapterNumber'] as num).toInt(),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CommentResponseImplToJson(
        _$CommentResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'userAvatar': instance.userAvatar,
      'novelId': instance.novelId,
      'volumeNumber': instance.volumeNumber,
      'chapterNumber': instance.chapterNumber,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
    };
