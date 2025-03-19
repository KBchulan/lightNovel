import 'package:json_annotation/json_annotation.dart';

part 'novel.g.dart';

@JsonSerializable()
class Novel {
  final String id;
  final String title;
  @JsonKey(defaultValue: '')
  final String author;
  @JsonKey(defaultValue: '')
  final String description;
  @JsonKey(defaultValue: '')
  final String cover;
  @JsonKey(defaultValue: 0)
  final int volumeCount;
  @JsonKey(defaultValue: [])
  final List<String> tags;
  @JsonKey(defaultValue: '')
  final String status; // 连载中、已完结
  @JsonKey(defaultValue: 0)
  final int readCount; // 阅读量
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  Novel({
    required this.id,
    required this.title,
    this.author = '',
    this.description = '',
    this.cover = '',
    this.volumeCount = 0,
    this.tags = const [],
    this.status = '',
    this.readCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Novel.fromJson(Map<String, dynamic> json) {
    // 处理 tags 字段为 null 的情况
    if (json['tags'] == null) {
      json['tags'] = [];
    }
    return _$NovelFromJson(json);
  }
  
  Map<String, dynamic> toJson() => _$NovelToJson(this);
} 