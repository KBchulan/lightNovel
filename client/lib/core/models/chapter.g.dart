// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChapterImpl _$$ChapterImplFromJson(Map<String, dynamic> json) =>
    _$ChapterImpl(
      id: json['id'] as String,
      novelId: json['novelId'] as String,
      volumeNumber: (json['volumeNumber'] as num).toInt(),
      chapterNumber: (json['chapterNumber'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      hasImages: json['hasImages'] as bool,
      imagePath: json['imagePath'] as String?,
      imageCount: (json['imageCount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ChapterImplToJson(_$ChapterImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'novelId': instance.novelId,
      'volumeNumber': instance.volumeNumber,
      'chapterNumber': instance.chapterNumber,
      'title': instance.title,
      'content': instance.content,
      'hasImages': instance.hasImages,
      'imagePath': instance.imagePath,
      'imageCount': instance.imageCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
