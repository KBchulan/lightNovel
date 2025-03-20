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
import 'api_provider.dart';

part 'novel_provider.g.dart';

@riverpod
class NovelNotifier extends _$NovelNotifier {
  ApiClient get _apiClient => ref.read(apiClientProvider);

  List<Novel>? _homeNovels;

  @override
  FutureOr<List<Novel>> build() async {
    _homeNovels = await _apiClient.getNovels();
    return _homeNovels ?? [];
  }

  Future<void> searchNovels(String keyword) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _apiClient.searchNovels(keyword: keyword));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    if (_homeNovels != null) {
      state = AsyncValue.data(_homeNovels!);
    } else {
      state = await AsyncValue.guard(() => _apiClient.getNovels());
    }
  }

  Future<void> refreshHome() async {
    state = const AsyncValue.loading();
    _homeNovels = await _apiClient.getNovels();
    state = AsyncValue.data(_homeNovels ?? []);
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
