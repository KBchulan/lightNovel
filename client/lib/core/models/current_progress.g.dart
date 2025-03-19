// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CurrentProgressImpl _$$CurrentProgressImplFromJson(
        Map<String, dynamic> json) =>
    _$CurrentProgressImpl(
      volumeNumber: (json['volumeNumber'] as num).toInt(),
      chapterNumber: (json['chapterNumber'] as num).toInt(),
      position: (json['position'] as num).toInt(),
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
    );

Map<String, dynamic> _$$CurrentProgressImplToJson(
        _$CurrentProgressImpl instance) =>
    <String, dynamic>{
      'volumeNumber': instance.volumeNumber,
      'chapterNumber': instance.chapterNumber,
      'position': instance.position,
      'lastReadAt': instance.lastReadAt.toIso8601String(),
    };
