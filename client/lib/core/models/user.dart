import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// 用户模型
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String avatar,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime lastActiveAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// 创建默认用户
  factory User.defaultUser() => User(
        id: '',
        name: '游客',
        avatar: '/static/avatars/default.png',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
} 