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