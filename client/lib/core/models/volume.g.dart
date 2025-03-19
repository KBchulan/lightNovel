// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VolumeImpl _$$VolumeImplFromJson(Map<String, dynamic> json) => _$VolumeImpl(
      id: json['id'] as String,
      novelId: json['novelId'] as String,
      volumeNumber: (json['volumeNumber'] as num).toInt(),
      chapterCount: (json['chapterCount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$VolumeImplToJson(_$VolumeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'novelId': instance.novelId,
      'volumeNumber': instance.volumeNumber,
      'chapterCount': instance.chapterCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
