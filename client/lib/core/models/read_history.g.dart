// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReadHistoryImpl _$$ReadHistoryImplFromJson(Map<String, dynamic> json) =>
    _$ReadHistoryImpl(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      novelId: json['novelId'] as String,
      lastRead: DateTime.parse(json['lastRead'] as String),
    );

Map<String, dynamic> _$$ReadHistoryImplToJson(_$ReadHistoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'novelId': instance.novelId,
      'lastRead': instance.lastRead.toIso8601String(),
    };
