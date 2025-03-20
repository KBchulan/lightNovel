// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReadRecordImpl _$$ReadRecordImplFromJson(Map<String, dynamic> json) =>
    _$ReadRecordImpl(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      novelId: json['novelId'] as String,
      volumeNumber: (json['volumeNumber'] as num).toInt(),
      chapterNumber: (json['chapterNumber'] as num).toInt(),
      startPosition: (json['startPosition'] as num).toInt(),
      endPosition: (json['endPosition'] as num).toInt(),
      readDuration: (json['readDuration'] as num).toInt(),
      isComplete: json['isComplete'] as bool,
      source: json['source'] as String,
      readAt: DateTime.parse(json['readAt'] as String),
    );

Map<String, dynamic> _$$ReadRecordImplToJson(_$ReadRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'novelId': instance.novelId,
      'volumeNumber': instance.volumeNumber,
      'chapterNumber': instance.chapterNumber,
      'startPosition': instance.startPosition,
      'endPosition': instance.endPosition,
      'readDuration': instance.readDuration,
      'isComplete': instance.isComplete,
      'source': instance.source,
      'readAt': instance.readAt.toIso8601String(),
    };
