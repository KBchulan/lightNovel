// ****************************************************************************
//
// @file       chapter_provider.dart
// @brief      章节目录相关状态管理
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/chapter_info.dart';
import 'api_provider.dart';

part 'chapter_provider.g.dart';

/// 章节目录状态
@riverpod
class ChapterNotifier extends _$ChapterNotifier {
  final Map<String, Map<int, List<ChapterInfo>>> _chaptersCache = {};

  @override
  Map<int, List<ChapterInfo>> build() {
    return {};
  }

  /// 获取指定卷的章节列表
  Future<List<ChapterInfo>> fetchChapters(String novelId, int volumeNumber) async {
    // 先从缓存中查找
    if (_chaptersCache[novelId]?[volumeNumber] != null) {
      state = _chaptersCache[novelId]!;
      return _chaptersCache[novelId]![volumeNumber]!;
    }

    // 从服务器获取
    final chapters = await ref.read(apiClientProvider).getChapters(
          novelId,
          volumeNumber,
        );

    // 更新缓存
    _chaptersCache[novelId] ??= {};
    _chaptersCache[novelId]![volumeNumber] = chapters;
    state = _chaptersCache[novelId]!;

    return chapters;
  }

  /// 清除指定小说的缓存
  void clearCache(String novelId) {
    _chaptersCache.remove(novelId);
    state = {};
  }

  /// 获取缓存的章节列表
  List<ChapterInfo>? getCachedChapters(String novelId, int volumeNumber) {
    return _chaptersCache[novelId]?[volumeNumber];
  }

  /// 检查是否已缓存
  bool isCached(String novelId, int volumeNumber) {
    return _chaptersCache[novelId]?[volumeNumber] != null;
  }
} 