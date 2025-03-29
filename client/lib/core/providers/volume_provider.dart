// ****************************************************************************
//
// @file       volume_provider.dart
// @brief      卷和章节管理的 Provider
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/volume.dart';
import '../models/chapter.dart';
import '../models/chapter_info.dart';
import 'api_provider.dart';

part 'volume_provider.g.dart';

// 创建一个简单的数据类来保存获取章节标题所需的参数
class ChapterTitleParams {
  final String novelId;
  final int volumeNumber;
  final int chapterNumber;

  const ChapterTitleParams({
    required this.novelId,
    required this.volumeNumber,
    required this.chapterNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterTitleParams &&
          runtimeType == other.runtimeType &&
          novelId == other.novelId &&
          volumeNumber == other.volumeNumber &&
          chapterNumber == other.chapterNumber;

  @override
  int get hashCode =>
      novelId.hashCode ^ volumeNumber.hashCode ^ chapterNumber.hashCode;
}

@riverpod
class VolumeNotifier extends _$VolumeNotifier {
  final Map<int, List<ChapterInfo>> _chaptersCache = {};

  @override
  FutureOr<List<Volume>> build() async {
    return const [];
  }

  Future<void> fetchVolumes(String novelId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(apiClientProvider).getVolumes(novelId);
    });
  }

  Future<List<ChapterInfo>> fetchChapters(
      String novelId, int volumeNumber) async {
    if (_chaptersCache.containsKey(volumeNumber)) {
      return _chaptersCache[volumeNumber]!;
    }

    final chapters = await ref.read(apiClientProvider).getChapters(novelId, volumeNumber);
    
    // 缓存章节信息
    _chaptersCache[volumeNumber] = chapters;
    
    return chapters;
  }

  Future<Chapter> fetchChapterContent(
      String novelId, int volumeNumber, int chapterNumber) async {
    return await ref
        .read(apiClientProvider)
        .getChapterContent(novelId, volumeNumber, chapterNumber);
  }
}

// 创建一个获取章节标题的Provider
final chapterTitleProvider = FutureProvider.autoDispose.family<String, ChapterTitleParams>(
  (ref, params) async {
    final apiClient = ref.read(apiClientProvider);
    
    try {
      // 获取章节列表
      final chapters = await apiClient.getChapters(params.novelId, params.volumeNumber);
      
      // 查找对应章节
      final matchingChapter = chapters.where((ch) => ch.chapterNumber == params.chapterNumber).toList();
      if (matchingChapter.isNotEmpty) {
        final title = matchingChapter.first.title;
        if (title.length > 11) {
          return '${title.substring(0, 11)}...';
        }
        return title;
      } else {
        return '第${params.chapterNumber}话';
      }
    } catch (e) {
      // 发生错误时返回默认标题
      return '第${params.chapterNumber}话';
    }
  },
);
