// ****************************************************************************
//
// @file       reading_provider.dart
// @brief      阅读相关的状态管理
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../models/chapter.dart';
import '../models/reading_progress.dart';
import '../models/read_history.dart';
import 'api_provider.dart';

part 'reading_provider.g.dart';

// 阅读模式
enum ReadingMode {
  scroll, // 滚动模式
  page,   // 翻页模式
}

// 阅读状态
class ReadingState {
  final Chapter? currentChapter;
  final ReadingMode readingMode;
  final bool showControls;
  final ReadingProgress? readingProgress;
  final List<ReadHistory> readHistory;

  const ReadingState({
    this.currentChapter,
    this.readingMode = ReadingMode.scroll,
    this.showControls = true,
    this.readingProgress,
    this.readHistory = const [],
  });

  ReadingState copyWith({
    Chapter? currentChapter,
    ReadingMode? readingMode,
    bool? showControls,
    ReadingProgress? readingProgress,
    List<ReadHistory>? readHistory,
  }) {
    return ReadingState(
      currentChapter: currentChapter ?? this.currentChapter,
      readingMode: readingMode ?? this.readingMode,
      showControls: showControls ?? this.showControls,
      readingProgress: readingProgress ?? this.readingProgress,
      readHistory: readHistory ?? this.readHistory,
    );
  }
}

@riverpod
class ReadingNotifier extends _$ReadingNotifier {
  @override
  ReadingState build() {
    return const ReadingState();
  }

  // 设置当前章节
  void setCurrentChapter(Chapter chapter) {
    state = state.copyWith(currentChapter: chapter);
  }

  // 设置阅读模式
  void setReadingMode(ReadingMode mode) {
    state = state.copyWith(readingMode: mode);
  }

  // 切换控制面板显示状态
  void toggleShowControls() {
    state = state.copyWith(showControls: !state.showControls);
  }

  // 设置控制面板显示状态
  void setShowControls(bool show) {
    state = state.copyWith(showControls: show);
  }

  // 更新阅读进度
  Future<void> updateReadingProgress({
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required int position,
  }) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      // 同时更新阅读进度和历史
      await Future.wait([
        apiClient.updateReadProgress(
          novelId: novelId,
          volumeNumber: volumeNumber,
          chapterNumber: chapterNumber,
          position: position,
        ),
        apiClient.updateReadHistory(novelId),
      ]);
      
      // 更新本地状态
      state = state.copyWith(
        readingProgress: ReadingProgress(
          id: '',
          deviceId: '',
          novelId: novelId,
          volumeNumber: volumeNumber,
          chapterNumber: chapterNumber,
          position: position,
          updatedAt: DateTime.now(),
        ),
      );
      
    } catch (e) {
      debugPrint('❌ 更新阅读进度错误: $e');
      rethrow;
    }
  }

  // 获取阅读进度
  Future<void> fetchReadingProgress(String novelId) async {
    debugPrint('Provider: 开始获取阅读进度，novelId: $novelId');
    try {
      final apiClient = ref.read(apiClientProvider);
      final progress = await apiClient.getReadProgress(novelId);
      debugPrint('Provider: 获取到阅读进度: $progress');
      state = state.copyWith(readingProgress: progress);
    } catch (e) {
      debugPrint('❌ Provider: 获取阅读进度错误: $e');
      rethrow;
    }
  }

  // 获取阅读历史
  Future<void> fetchReadHistory() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final history = await apiClient.getReadHistory();
      state = state.copyWith(readHistory: history);
    } catch (e) {
      debugPrint('❌ 获取阅读历史错误: $e');
      rethrow;
    }
  }

  // 清空阅读历史
  Future<void> clearReadHistory() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.clearReadHistory();
      state = state.copyWith(readHistory: []);
    } catch (e) {
      debugPrint('❌ 清空阅读历史错误: $e');
      rethrow;
    }
  }
} 