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

@riverpod
class VolumeNotifier extends _$VolumeNotifier {
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

  Future<List<ChapterInfo>> fetchChapters(String novelId, int volumeNumber) async {
    return await ref.read(apiClientProvider).getChapters(novelId, volumeNumber);
  }

  Future<Chapter> fetchChapterContent(String novelId, int volumeNumber, int chapterNumber) async {
    return await ref.read(apiClientProvider).getChapterContent(novelId, volumeNumber, chapterNumber);
  }
} 