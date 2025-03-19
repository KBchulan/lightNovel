// ****************************************************************************
//
// @file       novel_provider.dart
// @brief      提供给其他文件小说信息
//
// @author     KBchulan
// @date       2025/03/19
// @history    
// ****************************************************************************

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/api_client.dart';
import '../models/novel.dart';
import 'device_provider.dart';

part 'novel_provider.g.dart';

@riverpod
class NovelNotifier extends _$NovelNotifier {
  ApiClient get _apiClient => ref.read(apiClientProvider);

  @override
  FutureOr<List<Novel>> build() async {
    return _apiClient.getNovels();
  }

  Future<void> searchNovels(String keyword) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _apiClient.searchNovels(keyword: keyword));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _apiClient.getNovels());
  }
}

@riverpod
ApiClient apiClient(Ref ref) {
  final deviceService = ref.watch(deviceServiceProvider);
  return ApiClient(deviceService);
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
      return await ref.read(apiClientProvider).getFavorites();
    });
  }

  Future<void> addFavorite(String novelId) async {
    await ref.read(apiClientProvider).addFavorite(novelId);
    fetchFavorites();
  }

  Future<void> removeFavorite(String novelId) async {
    await ref.read(apiClientProvider).removeFavorite(novelId);
    fetchFavorites();
  }

  Future<bool> checkFavorite(String novelId) async {
    return await ref.read(apiClientProvider).checkFavorite(novelId);
  }
}
