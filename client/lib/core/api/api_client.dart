// ****************************************************************************
//
// @file       api_client.dart
// @brief      与后端API交互的客户端
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';
import '../services/device_service.dart';
import '../../config/app_config.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class ApiClient {
  final Dio _dio;
  final DeviceService _deviceService;
  WebSocketChannel? _wsChannel;

  ApiClient(this._deviceService)
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.connectionTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          responseType: ResponseType.json,
        )) {
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  // 连接WebSocket
  Future<WebSocketChannel> connectWebSocket() async {
    if (_wsChannel != null) {
      return _wsChannel!;
    }

    final deviceId = await _deviceService.getDeviceId();
    final wsUrl = Uri.parse('${AppConfig.wsBaseUrl}/ws')
        .replace(queryParameters: {'deviceId': deviceId});

    try {
      _wsChannel = WebSocketChannel.connect(wsUrl);
      return _wsChannel!;
    } catch (e) {
      debugPrint('❌ WebSocket连接错误: $e');
      rethrow;
    }
  }

  // 关闭WebSocket连接
  Future<void> closeWebSocket() async {
    await _wsChannel?.sink.close();
    _wsChannel = null;
  }

  Future<void> _onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      debugPrint('🌐 发起请求: ${options.uri}');
      final deviceId = await _deviceService.getDeviceId();
      options.headers['X-Device-ID'] = deviceId;
      handler.next(options);
    } catch (e) {
      debugPrint('❌ 请求预处理错误: $e');
      handler.reject(
        DioException(
          requestOptions: options,
          error: '获取设备ID失败: $e',
        ),
      );
    }
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      debugPrint('✅ 收到响应: ${response.requestOptions.uri}');
      debugPrint('📦 响应数据: ${response.data}');

      if (response.data != null && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('code') && data['code'] != 0) {
          debugPrint('❌ 业务错误: ${data['message']}');
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              error: data['message'] ?? '未知错误',
            ),
          );
          return;
        }
      }
      handler.next(response);
    } catch (e) {
      debugPrint('❌ 响应处理错误: $e');
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          error: '处理响应数据失败: $e',
        ),
      );
    }
  }

  Future<void> _onError(
      DioException err, ErrorInterceptorHandler handler) async {
    String message;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = '网络连接超时';
        break;
      case DioExceptionType.connectionError:
        message = '网络连接失败，请检查网络设置';
        break;
      case DioExceptionType.badResponse:
        message = '服务器响应错误: ${err.response?.statusCode}';
        break;
      default:
        message = err.error?.toString() ?? '未知错误';
    }

    debugPrint('❌ 请求错误: $message');
    debugPrint('🔍 错误详情: ${err.toString()}');

    err = DioException(
      requestOptions: err.requestOptions,
      error: message,
      type: err.type,
      response: err.response,
    );

    handler.next(err);
  }

  // 获取小说列表
  Future<List<Novel>> getNovels({
    int page = 1,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/novels',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据为空',
        );
      }

      if (data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误：缺少 data 字段',
        );
      }

      final pageData = data['data'] as Map<String, dynamic>;
      if (pageData['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误：缺少 data.data 字段',
        );
      }

      final novelsList = pageData['data'] as List;
      return novelsList
          .map((json) => Novel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 获取小说列表错误: $e');
      rethrow;
    }
  }

  // 获取最新小说
  Future<List<Novel>> getLatestNovels({int limit = 10}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/novels/latest',
        queryParameters: {'limit': limit},
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      final novelsList = data['data'] as List;
      return novelsList
          .map((json) => Novel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 获取最新小说错误: $e');
      rethrow;
    }
  }

  // 获取热门小说
  Future<List<Novel>> getPopularNovels({int limit = 10}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/novels/popular',
        queryParameters: {'limit': limit},
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      final novelsList = data['data'] as List;
      return novelsList
          .map((json) => Novel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 获取热门小说错误: $e');
      rethrow;
    }
  }

  // 搜索小说
  Future<List<Novel>> searchNovels({
    required String keyword,
    int page = 1,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/novels/search',
        queryParameters: {
          'keyword': keyword,
          'page': page,
          'size': size,
        },
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      final searchData = data['data'] as Map<String, dynamic>;
      final novelsList = searchData['items'] as List;
      return novelsList
          .map((json) => Novel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 搜索小说错误: $e');
      rethrow;
    }
  }

  // 获取小说详情
  Future<Novel> getNovelDetail(String novelId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/novels/$novelId',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      return Novel.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ 获取小说详情错误: $e');
      rethrow;
    }
  }

  // 获取卷列表
  Future<List<Volume>> getVolumes(String novelId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/novels/$novelId/volumes',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      final volumesList = data['data'] as List;
      return volumesList
          .map((json) => Volume.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 获取卷列表错误: $e');
      rethrow;
    }
  }

  // 获取章节列表
  Future<List<ChapterInfo>> getChapters(
      String novelId, int volumeNumber) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/novels/$novelId/volumes/$volumeNumber/chapters',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      final chaptersList = data['data'] as List;
      return chaptersList
          .map((json) => ChapterInfo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 获取章节列表错误: $e');
      rethrow;
    }
  }

  // 获取章节内容
  Future<Chapter> getChapterContent(
    String novelId,
    int volumeNumber,
    int chapterNumber,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/novels/$novelId/volumes/$volumeNumber/chapters/$chapterNumber',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      return Chapter.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ 获取章节内容错误: $e');
      rethrow;
    }
  }

  // 获取收藏列表
  Future<List<Novel>> getFavorites() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/user/favorites',
      );

      final data = response.data;
      if (data == null) {
        return [];
      }

      if (data['data'] == null) {
        return [];
      }

      final favoritesList = data['data'] as List;
      final novels = <Novel>[];
      final futures = <Future<void>>[];

      // 并行获取每个收藏小说的详情，提高效率
      for (final favorite in favoritesList) {
        final favoriteData = favorite as Map<String, dynamic>;
        final novelId = favoriteData['novelId'] as String;

        final future = getNovelDetail(novelId).then((novel) {
          novels.add(novel);
        }).catchError((e) {
          debugPrint('获取收藏小说详情出现异常: $e');
        });

        futures.add(future);
      }

      // 等待所有异步获取操作完成
      await Future.wait(futures);

      return novels;
    } catch (e) {
      debugPrint('获取收藏列表出现异常: $e');
      if (e is DioException) {
        rethrow;
      }
      if (e.toString().contains('null')) {
        return [];
      }
      rethrow;
    }
  }

  // 添加收藏
  Future<void> addFavorite(String novelId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/user/favorites/$novelId',
      );
    } catch (e) {
      debugPrint('❌ 添加收藏错误: $e');
      rethrow;
    }
  }

  // 取消收藏
  Future<void> removeFavorite(String novelId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/user/favorites/$novelId',
      );
    } catch (e) {
      debugPrint('❌ 取消收藏错误: $e');
      rethrow;
    }
  }

  // 检查是否已收藏
  Future<bool> checkFavorite(String novelId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/user/favorites/$novelId/check',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      final favoriteData = data['data'] as Map<String, dynamic>;
      return favoriteData['isFavorite'] as bool;
    } catch (e) {
      debugPrint('❌ 检查收藏状态错误: $e');
      rethrow;
    }
  }

  // 获取书签列表
  Future<List<Bookmark>> getBookmarks() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/user/bookmarks',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        debugPrint('📚 API: 书签列表为空');
        return [];
      }

      final bookmarksList = data['data'] as List;
      return bookmarksList
          .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 获取书签列表错误: $e');
      rethrow;
    }
  }

  // 创建书签
  Future<Bookmark> createBookmark({
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required int position,
    String? note,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/user/bookmarks',
        data: {
          'novelId': novelId,
          'volumeNumber': volumeNumber,
          'chapterNumber': chapterNumber,
          'position': position,
          if (note != null) 'note': note,
        },
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      return Bookmark.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ 创建书签错误: $e');
      rethrow;
    }
  }

  // 更新书签
  Future<Bookmark> updateBookmark(String bookmarkId, String note) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/user/bookmarks/$bookmarkId',
        data: {'note': note},
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      return Bookmark.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ 更新书签错误: $e');
      rethrow;
    }
  }

  // 删除书签
  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/user/bookmarks/$bookmarkId',
      );
    } catch (e) {
      debugPrint('❌ 删除书签错误: $e');
      rethrow;
    }
  }

  // 获取阅读历史
  Future<List<ReadHistory>> getReadHistory() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/user/reading/history',
      );

      final data = response.data;
      if (data == null) {
        debugPrint('📚 API: 阅读历史响应为空');
        return [];
      }

      if (data['data'] == null) {
        debugPrint('📚 API: 阅读历史为空');
        return [];
      }

      final historyList = data['data'] as List;
      final result = historyList
          .map((json) => ReadHistory.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('📚 API: 获取到 ${result.length} 条阅读历史');
      return result;
    } catch (e) {
      debugPrint('⚠️ API: 获取阅读历史出现异常: $e');
      if (e is DioException && e.error.toString().contains('响应数据格式错误')) {
        return [];
      }
      rethrow;
    }
  }

  // 更新阅读历史
  Future<void> updateReadHistory(String novelId, {DateTime? lastRead}) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/user/reading/history/$novelId',
        data: {
          if (lastRead != null) 'lastRead': lastRead.toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('❌ 更新阅读历史错误: $e');
      rethrow;
    }
  }

  // 删除阅读历史
  Future<void> deleteReadHistory(String novelId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/user/reading/history/$novelId',
      );
    } catch (e) {
      debugPrint('❌ 删除阅读历史错误: $e');
      rethrow;
    }
  }

  // 清空阅读历史
  Future<void> clearReadHistory() async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/user/reading/history',
      );
    } catch (e) {
      debugPrint('❌ 清空阅读历史错误: $e');
      rethrow;
    }
  }

  // 获取阅读进度
  Future<ReadingProgress?> getReadProgress(String novelId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/user/reading/progress/$novelId',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        debugPrint('❌ 获取阅读进度返回空数据，用户可能没有阅读记录');
        return null;
      }

      return ReadingProgress.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('❌ 获取阅读进度返回404, 用户没有阅读记录');
        return null;
      }
      debugPrint('❌ 获取阅读进度错误: $e');
      rethrow;
    } catch (e) {
      debugPrint('❌ 获取阅读进度错误: $e');
      rethrow;
    }
  }

  // 更新阅读进度
  Future<void> updateReadProgress({
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required int position,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/user/reading/progress/$novelId',
        data: {
          'volumeNumber': volumeNumber,
          'chapterNumber': chapterNumber,
          'position': position,
        },
      );
    } catch (e) {
      debugPrint('❌ 更新阅读进度错误: $e');
      rethrow;
    }
  }

  // 删除阅读进度
  Future<void> deleteReadProgress(String novelId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/user/reading/progress/$novelId',
      );
    } catch (e) {
      debugPrint('❌ 删除阅读进度错误: $e');
      rethrow;
    }
  }

  // 获取系统健康状态
  Future<Map<String, dynamic>> getHealth() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/health',
      );

      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      return data;
    } catch (e) {
      debugPrint('❌ 获取系统健康状态错误: $e');
      rethrow;
    }
  }

  // 获取系统性能指标
  Future<Map<String, dynamic>> getMetrics() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/metrics',
      );

      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      return data;
    } catch (e) {
      debugPrint('❌ 获取系统性能指标错误: $e');
      rethrow;
    }
  }

  // WebSocket连接状态
  Future<Map<String, dynamic>> getWebSocketStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/ws/status',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      return data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ 获取WebSocket状态错误: $e');
      rethrow;
    }
  }

  // 拼接小说图片路径
  Future<String> getNovelImageUrl(String novelId, String imagePath, int imageIndex) async {
    try {
      final novel = await getNovelDetail(novelId);
      final novelTitle = novel.title;

      final formattedIndex = imageIndex.toString().padLeft(3, '0');

      final formattedPath = imagePath.replaceFirst('//', '/$novelTitle/');

      final imageUrl =
          '${AppConfig.staticUrl}/$formattedPath/$formattedIndex.jpg';

      return imageUrl;
    } catch (e) {
      debugPrint('❌ 拼接小说图片路径错误: $e');
      throw DioException(
        requestOptions: RequestOptions(path: '/'),
        error: '拼接小说图片路径错误: $e',
      );
    }
  }

  // 批量获取章节所有图片的URL
  Future<List<String>> getChapterImageUrls(Chapter chapter) async {
    if (!chapter.hasImages ||
        chapter.imagePath == null ||
        chapter.imageCount <= 0) {
      return [];
    }

    try {
      final novel = await getNovelDetail(chapter.novelId);
      final novelTitle = novel.title;

      final formattedPath =
          chapter.imagePath!.replaceFirst('//', '/$novelTitle/');

      final imageUrls = List.generate(chapter.imageCount, (index) {
        final imageIndex = (index + 1).toString().padLeft(3, '0');
        return '${AppConfig.staticUrl}/$formattedPath/$imageIndex.jpg';
      });

      return imageUrls;
    } catch (e) {
      debugPrint('❌ 批量获取章节图片URL错误: $e');
      return [];
    }
  }

  // 获取用户资料
  Future<User> getUserProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/user/profile',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      return User.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ 获取用户资料错误: $e');
      rethrow;
    }
  }

  // 更新用户资料
  Future<User> updateUserProfile({
    String? name,
    String? avatar,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/user/profile',
        data: {
          if (name != null) 'name': name,
          if (avatar != null) 'avatar': avatar,
        },
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      return User.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ 更新用户资料错误: $e');
      rethrow;
    }
  }

  // 获取章节评论
  Future<List<CommentResponse>> getChapterComments({
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/novels/$novelId/volumes/$volumeNumber/chapters/$chapterNumber/comments',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      final pageData = data['data'] as Map<String, dynamic>;
      if (pageData['data'] == null) {
        return [];
      }

      final commentsList = pageData['data'] as List;
      return commentsList
          .map((json) => CommentResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 获取章节评论错误: $e');
      rethrow;
    }
  }

  // 发表评论
  Future<Comment> createComment({
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required String content,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/novels/$novelId/volumes/$volumeNumber/chapters/$chapterNumber/comments',
        data: {
          'content': content,
        },
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      return Comment.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ 发表评论错误: $e');
      rethrow;
    }
  }

  // 删除评论
  Future<void> deleteComment(String commentId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/comments/$commentId',
      );
    } catch (e) {
      debugPrint('❌ 删除评论错误: $e');
      rethrow;
    }
  }

  // 上传用户头像
  Future<String> uploadAvatar(List<int> imageBytes, String fileName) async {
    try {
      // 检查文件类型
      final fileExt = fileName.split('.').last.toLowerCase();
      final mimeType = _getMimeTypeFromExtension(fileExt);
      
      if (mimeType == null) {
        throw DioException(
          requestOptions: RequestOptions(path: '/user/upload/avatar'),
          error: '不支持的文件类型, 仅支持JPG和PNG格式',
        );
      }
      
      if (imageBytes.length > 10 * 1024 * 1024) {
        throw DioException(
          requestOptions: RequestOptions(path: '/user/upload/avatar'),
          error: '文件大小超过限制(10MB)',
        );
      }
      
      final multipartFile = MultipartFile.fromBytes(
        imageBytes,
        filename: 'avatar.$fileExt',
        contentType: MediaType.parse(mimeType),
      );
      
      final formData = FormData.fromMap({
        'file': multipartFile,
      });
      
      final response = await _dio.post<Map<String, dynamic>>(
        '/user/upload/avatar',
        data: formData,
      );
      
      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }
      
      return data['data']['url'] as String;
    } catch (e) {
      debugPrint('❌ 上传头像错误: $e');
      rethrow;
    }
  }

  // 从文件上传用户头像
  Future<String> uploadAvatarFile(File file) async {
    try {
      // 检查文件类型
      final fileExt = file.path.split('.').last.toLowerCase();
      final mimeType = _getMimeTypeFromExtension(fileExt);
      
      if (mimeType == null) {
        throw DioException(
          requestOptions: RequestOptions(path: '/user/upload/avatar'),
          error: '不支持的文件类型, 仅支持JPG和PNG格式',
        );
      }
      
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw DioException(
          requestOptions: RequestOptions(path: '/user/upload/avatar'),
          error: '文件大小超过限制(10MB)',
        );
      }
      
      final fileBytes = await file.readAsBytes();
      final multipartFile = MultipartFile.fromBytes(
        fileBytes,
        filename: 'avatar.$fileExt',
        contentType: MediaType.parse(mimeType),
      );
      
      final formData = FormData.fromMap({
        'file': multipartFile,
      });
      
      final response = await _dio.post<Map<String, dynamic>>(
        '/user/upload/avatar',
        data: formData,
      );
      
      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }
      
      return data['data']['url'] as String;
    } catch (e) {
      debugPrint('❌ 上传头像文件错误: $e');
      rethrow;
    }
  }
  
  // 获取文件的MIME类型
  String? _getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return null;
    }
  }

  // 上传头像并更新用户资料
  Future<User> uploadAvatarAndUpdateProfile(File avatarFile, {String? name}) async {
    try {
      // 上传头像
      final avatarUrl = await uploadAvatarFile(avatarFile);
      
      // 更新用户资料
      return await updateUserProfile(
        avatar: avatarUrl,
        name: name,
      );
    } catch (e) {
      debugPrint('❌ 上传头像并更新用户资料错误: $e');
      rethrow;
    }
  }
}
