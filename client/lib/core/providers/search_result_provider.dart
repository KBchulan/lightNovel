// ****************************************************************************
//
// @file       search_result_provider.dart
// @brief      搜索结果状态管理
//
// @author     KBchulan
// @date       2025/03/19
// @history    
// ****************************************************************************

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/novel.dart';
import 'novel_provider.dart';

part 'search_result_provider.g.dart';

@Riverpod(keepAlive: true)
class SearchResult extends _$SearchResult {
  @override
  FutureOr<List<Novel>> build() {
    return const [];
  }

  Future<void> search(String keyword) async {
    if (keyword.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    final api = ref.read(apiClientProvider);
    state = await AsyncValue.guard(() => api.searchNovels(keyword: keyword));
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
} 