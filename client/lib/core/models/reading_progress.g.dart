// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReadingProgressImpl _$$ReadingProgressImplFromJson(
        Map<String, dynamic> json) =>
    _$ReadingProgressImpl(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      novelId: json['novelId'] as String,
      volumeNumber: (json['volumeNumber'] as num).toInt(),
      chapterNumber: (json['chapterNumber'] as num).toInt(),
      position: (json['position'] as num).toInt(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ReadingProgressImplToJson(
        _$ReadingProgressImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'novelId': instance.novelId,
      'volumeNumber': instance.volumeNumber,
      'chapterNumber': instance.chapterNumber,
      'position': instance.position,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
