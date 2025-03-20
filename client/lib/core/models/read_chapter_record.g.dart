// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_chapter_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReadChapterRecordImpl _$$ReadChapterRecordImplFromJson(
        Map<String, dynamic> json) =>
    _$ReadChapterRecordImpl(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      novelId: json['novelId'] as String,
      volumeNumber: (json['volumeNumber'] as num).toInt(),
      chapterNumber: (json['chapterNumber'] as num).toInt(),
      lastPosition: (json['lastPosition'] as num).toInt(),
      readCount: (json['readCount'] as num).toInt(),
      isComplete: json['isComplete'] as bool,
      firstReadAt: DateTime.parse(json['firstReadAt'] as String),
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
    );

Map<String, dynamic> _$$ReadChapterRecordImplToJson(
        _$ReadChapterRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'novelId': instance.novelId,
      'volumeNumber': instance.volumeNumber,
      'chapterNumber': instance.chapterNumber,
      'lastPosition': instance.lastPosition,
      'readCount': instance.readCount,
      'isComplete': instance.isComplete,
      'firstReadAt': instance.firstReadAt.toIso8601String(),
      'lastReadAt': instance.lastReadAt.toIso8601String(),
    };
