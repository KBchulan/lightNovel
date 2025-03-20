// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_stat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReadingStatImpl _$$ReadingStatImplFromJson(Map<String, dynamic> json) =>
    _$ReadingStatImpl(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      novelId: json['novelId'] as String,
      chapterRead: (json['chapterRead'] as num).toInt(),
      totalChapters: (json['totalChapters'] as num).toInt(),
      completeCount: (json['completeCount'] as num).toInt(),
      totalReadTime: (json['totalReadTime'] as num).toInt(),
      readProgress: (json['readProgress'] as num).toDouble(),
      readDays:
          (json['readDays'] as List<dynamic>).map((e) => e as String).toList(),
      lastActiveDate: DateTime.parse(json['lastActiveDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ReadingStatImplToJson(_$ReadingStatImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'novelId': instance.novelId,
      'chapterRead': instance.chapterRead,
      'totalChapters': instance.totalChapters,
      'completeCount': instance.completeCount,
      'totalReadTime': instance.totalReadTime,
      'readProgress': instance.readProgress,
      'readDays': instance.readDays,
      'lastActiveDate': instance.lastActiveDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
