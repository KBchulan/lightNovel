// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NovelImpl _$$NovelImplFromJson(Map<String, dynamic> json) => _$NovelImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      volumeCount: (json['volumeCount'] as num?)?.toInt() ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      status: json['status'] as String? ?? '',
      readCount: (json['readCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$NovelImplToJson(_$NovelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'description': instance.description,
      'cover': instance.cover,
      'volumeCount': instance.volumeCount,
      'tags': instance.tags,
      'status': instance.status,
      'readCount': instance.readCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
