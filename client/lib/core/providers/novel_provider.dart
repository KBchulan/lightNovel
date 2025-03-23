// ****************************************************************************
//
// @file       novel_provider.dart
// @brief      提供给其他文件小说信息
//
// @author     KBchulan
// @date       2025/03/19
// @history    
// ****************************************************************************

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/api_client.dart';
import '../models/novel.dart';
import 'api_provider.dart';

part 'novel_provider.g.dart';

@riverpod
class NovelNotifier extends _$NovelNotifier {
  ApiClient get _apiClient => ref.read(apiClientProvider);

  List<Novel>? _homeNovels;

  @override
  FutureOr<List<Novel>> build() async {
    // 确保初始状态加载完整列表
    _homeNovels = await _apiClient.getNovels();
    return _homeNovels ?? [];
  }

  Future<void> searchNovels(String keyword) async {
    state = const AsyncValue.loading();
    final searchResult = await AsyncValue.guard(() => _apiClient.searchNovels(keyword: keyword));
    state = searchResult;
  }

  // 添加设置加载状态的方法，用于显示加载UI但不执行实际搜索
  void setLoading() {
    state = const AsyncValue.loading();
  }

  Future<void> refresh() async {
    // 如果是从搜索页面返回，则应该显示全部小说列表
    
    if (_homeNovels != null) {
      state = AsyncValue.data(_homeNovels!);
    } else {
      state = const AsyncValue.loading();
      final novels = await AsyncValue.guard(() => _apiClient.getNovels());
      _homeNovels = novels.valueOrNull;
      state = novels;
    }
  }

  Future<void> refreshHome() async {
    state = const AsyncValue.loading();
    _homeNovels = await _apiClient.getNovels();
    state = AsyncValue.data(_homeNovels ?? []);
  }

  // 添加获取首页小说的方法
  List<Novel> getHomeNovels() {
    return _homeNovels ?? [];
  }
}

@riverpod
class FavoriteNotifier extends _$FavoriteNotifier {
  @override
  FutureOr<List<Novel>> build() async {
    return const [];
  }

  Future<void> fetchFavorites() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        return await ref.read(apiClientProvider).getFavorites();
      } catch (e) {
        // 如果是空响应导致的错误，返回空列表
        if (e.toString().contains('null')) {
          return const [];
        }
        rethrow;
      }
    });
  }
}
