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
    _fetchHistory().then((_) {
      if (state.hasValue) {
        ref.read(historySortTypeProvider.notifier).state = 'time';
        ref.read(historySortOrderProvider.notifier).state = false;
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
      ref.read(historySortTypeProvider.notifier).state = 'time';
      ref.read(historySortOrderProvider.notifier).state = false;
      
      // 设置加载完成标志
      ref.read(historyLoadingCompleteProvider.notifier).state = true;
    } catch (e) {
      debugPrint('❌ 获取历史记录错误: $e');
      if (e is DioException && e.error.toString().contains('响应数据格式错误')) {
        state = const AsyncValue.data([]);
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
      
      // 即使出错也设置加载完成标志
      ref.read(historyLoadingCompleteProvider.notifier).state = true;
    }
  }

  // 显式刷新历史记录，用于用户操作时调用
  Future<void> refresh() async {
    // 重置加载完成标志
    ref.read(historyLoadingCompleteProvider.notifier).state = false;
    
    state = const AsyncValue.loading();
    await _fetchHistory();

    _notifyHistoryChange();

    debugPrint('✅ 刷新历史记录成功');
  }

  // 清空阅读历史
  Future<void> clearHistory() async {
    try {
      state = const AsyncValue.loading();
      final apiClient = ref.read(apiClientProvider);
      await apiClient.clearReadHistory();
      state = const AsyncValue.data([]);

      _notifyHistoryChange();

      // 清空成功后设置加载完成标志
      ref.read(historyLoadingCompleteProvider.notifier).state = true;
      
      debugPrint('✅ 清空历史记录成功');
    } catch (e) {
      debugPrint('❌ 清空阅读历史错误: $e');
      state = AsyncValue.error(e, StackTrace.current);
      
      // 即使出错也设置加载完成标志
      ref.read(historyLoadingCompleteProvider.notifier).state = true;
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

      // 触发历史变更通知，包含被删除的小说ID
      _notifyHistoryChange(deletedNovelId: novelId);

      debugPrint('✅ 删除历史记录成功: $novelId');
    } catch (e) {
      debugPrint('❌ 删除历史记录错误: $e');
      // 如果删除失败，重新获取正确的数据
      await _fetchHistory();
    }
  }

  // 通知历史记录变更的方法
  void _notifyHistoryChange({String? deletedNovelId}) {
    // 更新历史变更通知器
    ref.read(historyChangeNotifierProvider.notifier).state = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'deletedNovelId': deletedNovelId,
    };

    // 如果有删除的小说ID，同时使该小说的进度Provider失效
    if (deletedNovelId != null) {
      ref.invalidate(historyProgress(deletedNovelId));
    }
  }

  // 按时间排序
  void sortByTime() {
    final currentData = state.valueOrNull ?? [];
    // 保持列表不变，具体的分组和排序工作在HistoryPage中完成
    final sortedHistories = List<ReadHistory>.from(currentData);

    state = AsyncValue.data(sortedHistories);
    ref.read(historySortTypeProvider.notifier).state = 'time';
  }

  // 按名称排序
  void sortByName() async {
    final currentData = state.valueOrNull ?? [];
    // isAscending仅影响组内排序，这里我们保留原有数据
    // 组内排序在HistoryPage中实现

    if (currentData.isEmpty) return;

    try {
      // 获取所有小说的详细信息
      final novels = await Future.wait(
        currentData.map((history) =>
            ref.read(apiClientProvider).getNovelDetail(history.novelId)),
      );

      // 创建历史记录和小说标题的映射
      final titleMap = <String, String>{};

      for (int i = 0; i < currentData.length; i++) {
        final history = currentData[i];
        final novel = novels[i];
        titleMap[history.novelId] = novel.title;
      }

      // 不对整体列表进行排序，而是保存标题映射供HistoryPage使用
      final sortedHistories = List<ReadHistory>.from(currentData);

      // 更新状态
      state = AsyncValue.data(sortedHistories);

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
  // 监听历史变更通知器，当历史记录发生变化时自动刷新
  ref.watch(historyChangeNotifierProvider);

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

// 历史记录变更通知器 - 用于通知其他组件历史记录已经发生变化
final historyChangeNotifierProvider =
    StateProvider<Map<String, dynamic>>((ref) => {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'deletedNovelId': null,
        });

// 排序类型：time 或 name
final historySortTypeProvider = StateProvider<String>((ref) => 'time');

// 排序顺序：true 为升序，false 为降序
final historySortOrderProvider = StateProvider<bool>((ref) => false);

// 存储小说ID到标题的映射，用于按名称排序
final historyTitleMapProvider = StateProvider<Map<String, String>>((ref) => {});

// 历史记录加载完成的标志 - 用于控制动画
final historyLoadingCompleteProvider = StateProvider<bool>((ref) => false);
