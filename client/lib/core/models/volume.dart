// ****************************************************************************
//
// @file       volume.dart
// @brief      卷模型
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************
import 'package:freezed_annotation/freezed_annotation.dart';

part 'volume.freezed.dart';
part 'volume.g.dart';

@freezed
class Volume with _$Volume {
  const factory Volume({
    required String id,
    required String novelId,
    required int volumeNumber,
    required int chapterCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Volume;

  factory Volume.fromJson(Map<String, dynamic> json) => _$VolumeFromJson(json);
}
