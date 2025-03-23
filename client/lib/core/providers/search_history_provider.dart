// ****************************************************************************
//
// @file       search_history_provider.dart
// @brief      搜索历史状态管理
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/storage_service.dart';

part 'search_history_provider.g.dart';

@Riverpod(keepAlive: true)
class SearchHistory extends _$SearchHistory {
  static const maxHistoryItems = 10;
  static const _storageKey = 'search_history';

  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  FutureOr<List<String>> build() async {
    return _storage.getStringList(_storageKey);
  }

  Future<void> addSearch(String keyword) async {
    if (keyword.isEmpty) return;

    final currentState = await future;
    final newHistory = List<String>.from(currentState);

    // 如果已存在，先移除旧的
    newHistory.remove(keyword);
    // 添加到开头
    newHistory.insert(0, keyword);
    // 保持最大数量
    if (newHistory.length > maxHistoryItems) {
      newHistory.removeLast();
    }

    await _storage.saveStringList(_storageKey, newHistory);
    state = AsyncData(newHistory);
  }

  Future<void> removeSearch(String keyword) async {
    final currentState = await future;
    final newHistory = currentState.where((item) => item != keyword).toList();

    await _storage.saveStringList(_storageKey, newHistory);
    state = AsyncData(newHistory);
  }

  Future<void> clearHistory() async {
    await _storage.remove(_storageKey);
    state = const AsyncData(<String>[]);
  }
}
