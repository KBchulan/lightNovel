// ****************************************************************************
//
// @file       bookmark_provider.dart
// @brief      书签状态管理
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/bookmark.dart';
import 'api_provider.dart';

part 'bookmark_provider.g.dart';

@Riverpod(keepAlive: true)
class BookmarkNotifier extends _$BookmarkNotifier {
  @override
  FutureOr<List<Bookmark>> build() async {
    return _fetchBookmarks();
  }

  Future<List<Bookmark>> _fetchBookmarks() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final bookmarks = await apiClient.getBookmarks();
      return bookmarks;
    } catch (e) {
      // 出错时返回空列表
      rethrow;
    }
  }

  // 创建书签
  Future<Bookmark?> createBookmark({
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required int position,
    required String note,
  }) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final bookmark = await apiClient.createBookmark(
        novelId: novelId,
        volumeNumber: volumeNumber,
        chapterNumber: chapterNumber,
        position: position,
        note: note,
      );
      
      // 更新状态
      state = await AsyncValue.guard(() async {
        final currentBookmarks = state.value ?? [];
        return [bookmark, ...currentBookmarks];
      });
      
      return bookmark;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }
  
  // 更新书签
  Future<bool> updateBookmark(String id, String note) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final updatedBookmark = await apiClient.updateBookmark(id, note);
      
      // 更新状态
      state = await AsyncValue.guard(() async {
        final currentBookmarks = state.value ?? [];
        final index = currentBookmarks.indexWhere((bookmark) => bookmark.id == id);
        
        if (index != -1) {
          final updatedList = List<Bookmark>.from(currentBookmarks);
          updatedList[index] = updatedBookmark;
          return updatedList;
        }
        
        return currentBookmarks;
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // 删除书签
  Future<bool> deleteBookmark(String id) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteBookmark(id);
      
      // 更新状态
      state = await AsyncValue.guard(() async {
        final currentBookmarks = state.value ?? [];
        return currentBookmarks.where((bookmark) => bookmark.id != id).toList();
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // 刷新书签列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchBookmarks);
  }
}

// 获取指定小说的书签
@riverpod
Future<List<Bookmark>> novelBookmarks(Ref ref, String novelId) async {
  final allBookmarks = await ref.watch(bookmarkNotifierProvider.future);
  return allBookmarks.where((bookmark) => bookmark.novelId == novelId).toList();
} 