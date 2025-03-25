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
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _fetchHistory().then((_) {
      // 获取历史记录后应用默认排序
      if (state.hasValue) {
        sortByTime(); // 默认按时间排序
      }
    });
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

      // 按最后阅读时间降序排序（最新的记录排在前面）
      final sortedHistories = uniqueHistories.values.toList()
        ..sort((a, b) => b.lastRead.compareTo(a.lastRead)); // 默认降序排序：从新到旧

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
      final updatedHistories =
          currentData.where((history) => history.novelId != novelId).toList();

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

  // 按时间排序
  void sortByTime() {
    final currentData = state.valueOrNull ?? [];
    final isAscending = ref.read(historySortOrderProvider);
    
    final sortedHistories = List<ReadHistory>.from(currentData)
      ..sort((a, b) => isAscending 
          ? a.lastRead.compareTo(b.lastRead)  // 升序：从旧到新
          : b.lastRead.compareTo(a.lastRead)); // 降序：从新到旧
          
    state = AsyncValue.data(sortedHistories);
    ref.read(historySortTypeProvider.notifier).state = 'time';
  }

  // 按名称排序
  void sortByName() async {
    final currentData = state.valueOrNull ?? [];
    final isAscending = ref.read(historySortOrderProvider);
    
    if (currentData.isEmpty) return;

    try {
      // 获取所有小说的详细信息
      final novels = await Future.wait(
        currentData.map((history) =>
            ref.read(apiClientProvider).getNovelDetail(history.novelId)),
      );

      // 创建历史记录和小说标题的映射和字典
      final historyWithTitles = <MapEntry<ReadHistory, String>>[];
      final titleMap = <String, String>{}; // 用于存储novelId到标题的映射
      
      for (int i = 0; i < currentData.length; i++) {
        final history = currentData[i];
        final novel = novels[i];
        historyWithTitles.add(MapEntry(history, novel.title));
        titleMap[history.novelId] = novel.title;
      }

      // 按标题排序
      historyWithTitles.sort((a, b) => isAscending
          ? a.value.compareTo(b.value)  // 升序：A到Z
          : b.value.compareTo(a.value)); // 降序：Z到A

      // 更新状态
      state = AsyncValue.data(historyWithTitles.map((e) => e.key).toList());
      
      // 保存标题映射到临时存储，供日期组内排序使用
      ref.read(historyTitleMapProvider.notifier).state = titleMap;
      
      ref.read(historySortTypeProvider.notifier).state = 'name';
    } catch (e) {
      debugPrint('❌ 按名称排序错误: $e');
    }
  }
  
  // 切换排序顺序并重新排序
  void toggleSortOrder() {
    final currentOrder = ref.read(historySortOrderProvider);
    ref.read(historySortOrderProvider.notifier).state = !currentOrder;
    
    // 根据当前排序类型重新排序
    final sortType = ref.read(historySortTypeProvider);
    if (sortType == 'time') {
      sortByTime();
    } else {
      sortByName();
    }
  }
}

// 使用手动创建Provider的方式，避免使用自动生成的代码
final historyNovelProvider =
    FutureProvider.family<Novel?, String>((ref, novelId) async {
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
final historyProgress =
    FutureProvider.family<ReadingProgress?, String>((ref, novelId) async {
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

// 排序类型：time 或 name
final historySortTypeProvider = StateProvider<String>((ref) => 'time');

// 排序顺序：true 为升序，false 为降序
final historySortOrderProvider = StateProvider<bool>((ref) => false); // 默认降序

// 存储小说ID到标题的映射，用于按名称排序
final historyTitleMapProvider = StateProvider<Map<String, String>>((ref) => {});
