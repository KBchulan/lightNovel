import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/api_client.dart';
import '../models/novel.dart';
import 'device_provider.dart';

part 'novel_provider.g.dart';

@riverpod
class NovelNotifier extends _$NovelNotifier {
  @override
  Future<List<Novel>> build() async {
    return _fetchNovels();
  }

  Future<List<Novel>> _fetchNovels() async {
    final apiClient = ref.read(apiClientProvider);
    return apiClient.getNovels();
  }

  Future<List<Novel>> fetchLatestNovels() async {
    final apiClient = ref.read(apiClientProvider);
    return apiClient.getLatestNovels();
  }

  Future<List<Novel>> fetchPopularNovels() async {
    final apiClient = ref.read(apiClientProvider);
    return apiClient.getPopularNovels();
  }

  Future<List<Novel>> searchNovels(String keyword) async {
    final apiClient = ref.read(apiClientProvider);
    return apiClient.searchNovels(keyword: keyword);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchNovels());
  }
}

@riverpod
ApiClient apiClient(ApiClientRef ref) {
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
      final response = await ref.read(apiClientProvider).get('/user/favorites');
      return (response as List)
          .map((e) => Novel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> addFavorite(String novelId) async {
    await ref.read(apiClientProvider).post('/user/favorites/$novelId');
    fetchFavorites();
  }

  Future<void> removeFavorite(String novelId) async {
    await ref.read(apiClientProvider).delete('/user/favorites/$novelId');
    fetchFavorites();
  }

  Future<bool> checkFavorite(String novelId) async {
    final response = await ref.read(apiClientProvider).get(
      '/user/favorites/$novelId/check',
    );
    return response as bool;
  }
} 