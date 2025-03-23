// ****************************************************************************
//
// @file       history_provider.dart
// @brief      历史记录相关的 Provider
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/read_history.dart';
import '../models/novel.dart';
import '../models/reading_progress.dart';
import 'api_provider.dart';

part 'history_provider.g.dart';

// 使用keepAlive保证Provider在整个应用生命周期内保持活跃
@Riverpod(keepAlive: true)
class HistoryNotifier extends _$HistoryNotifier {
  @override
  AsyncValue<List<ReadHistory>> build() {
    // 返回初始加载状态，然后立即开始获取数据
    _fetchHistory();
    return const AsyncValue.loading();
  }

  // 获取历史记录
  Future<void> _fetchHistory() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.getReadHistory();
      
      // 确保历史记录的唯一性，使用 Map 来去重
      final uniqueHistories = <String, ReadHistory>{};
      for (final history in result) {
        uniqueHistories[history.novelId] = history;
      }
      
      // 按最后阅读时间排序
      final sortedHistories = uniqueHistories.values.toList()
        ..sort((a, b) => b.lastRead.compareTo(a.lastRead));
      
      state = AsyncValue.data(sortedHistories);
    } catch (e) {
      debugPrint('❌ 获取历史记录错误: $e');
      if (e is DioException && e.error.toString().contains('响应数据格式错误')) {
        state = const AsyncValue.data([]);
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  // 显式刷新历史记录，用于用户操作时调用
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _fetchHistory();
    debugPrint('✅ 刷新历史记录成功');
  }

  // 清空阅读历史
  Future<void> clearHistory() async {
    try {
      state = const AsyncValue.loading();
      final apiClient = ref.read(apiClientProvider);
      await apiClient.clearReadHistory();
      state = const AsyncValue.data([]);
      debugPrint('✅ 清空历史记录成功');
    } catch (e) {
      debugPrint('❌ 清空阅读历史错误: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // 删除单条历史记录
  Future<void> deleteHistory(String novelId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final currentData = state.valueOrNull ?? [];
      
      // 先乐观更新UI
      final updatedHistories = currentData
          .where((history) => history.novelId != novelId)
          .toList();
      
      state = AsyncValue.data(updatedHistories);
      
      // 然后执行实际删除操作
      await Future.wait([
        apiClient.deleteReadHistory(novelId),
        apiClient.deleteReadProgress(novelId),
      ]);
      
      debugPrint('✅ 删除历史记录成功: $novelId');
    } catch (e) {
      debugPrint('❌ 删除历史记录错误: $e');
      // 如果删除失败，重新获取正确的数据
      await _fetchHistory();
    }
  }
}

// 使用手动创建Provider的方式，避免使用自动生成的代码
final historyNovelProvider = FutureProvider.family<Novel?, String>((ref, novelId) async {
  ref.keepAlive();
  try {
    final apiClient = ref.read(apiClientProvider);
    final novel = await apiClient.getNovelDetail(novelId);
    return novel;
  } catch (e) {
    debugPrint('❌ 获取历史小说详情错误: $e');
    return null;
  }
});

// 使用手动创建Provider的方式，避免使用自动生成的代码
final historyProgress = FutureProvider.family<ReadingProgress?, String>((ref, novelId) async {
  final apiClient = ref.read(apiClientProvider);
  try {
    // API可能返回null
    final progress = await apiClient.getReadProgress(novelId);
    return progress;
  } catch (e) {
    debugPrint('❌ 获取历史阅读进度错误: $e');
    rethrow;
  }
}); 