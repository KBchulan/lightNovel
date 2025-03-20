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
import '../models/novel.dart';
import '../models/volume.dart';
import '../models/chapter.dart';
import '../models/chapter_info.dart';
import '../models/bookmark.dart';
import '../models/reading_progress.dart';
import '../models/read_chapter_record.dart';
import '../models/read_record.dart';
import '../models/reading_stat.dart';
import '../services/device_service.dart';
import '../../config/app_config.dart';

class ApiClient {
  final Dio _dio;
  final DeviceService _deviceService;

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
        '/favorites',
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
      debugPrint('❌ 获取收藏列表错误: $e');
      rethrow;
    }
  }

  // 添加收藏
  Future<void> addFavorite(String novelId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/favorites/$novelId',
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
        '/favorites/$novelId',
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
        '/favorites/$novelId/check',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      return data['data'] as bool;
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
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
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
  Future<List<ReadingProgress>> getReadingHistory({int limit = 10}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/user/history',
        queryParameters: {'limit': limit},
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      final historyList = data['data'] as List;
      return historyList
          .map((json) => ReadingProgress.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 获取阅读历史错误: $e');
      rethrow;
    }
  }

  // 更新阅读进度
  Future<void> updateReadingProgress({
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required int position,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/user/progress',
        data: {
          'novelId': novelId,
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

  // 获取已读章节列表
  Future<List<ReadChapterRecord>> getReadChapters(String novelId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/user/reading/chapters/$novelId',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      final recordsList = data['data'] as List;
      return recordsList
          .map((json) => ReadChapterRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 获取已读章节列表错误: $e');
      rethrow;
    }
  }

  // 获取阅读记录
  Future<List<ReadRecord>> getReadingRecords(
    String novelId, {
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/user/reading/records/$novelId',
        queryParameters: {
          if (page != null) 'page': page,
          if (pageSize != null) 'page_size': pageSize,
        },
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      final recordsList = data['data'] as List;
      return recordsList
          .map((json) => ReadRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 获取阅读记录错误: $e');
      rethrow;
    }
  }

  // 删除阅读记录
  Future<void> deleteReadingRecord(String novelId, String recordId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/user/reading/records/$novelId/$recordId',
      );
    } catch (e) {
      debugPrint('❌ 删除阅读记录错误: $e');
      rethrow;
    }
  }

  // 添加阅读记录
  Future<void> addReadRecord({
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required int readDuration,
    required String source,
    int? startPosition,
    int? endPosition,
    bool? isComplete,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/user/reading/records',
        data: {
          'novelId': novelId,
          'volumeNumber': volumeNumber,
          'chapterNumber': chapterNumber,
          'readDuration': readDuration,
          'source': source,
          if (startPosition != null) 'startPosition': startPosition,
          if (endPosition != null) 'endPosition': endPosition,
          if (isComplete != null) 'isComplete': isComplete,
        },
      );
    } catch (e) {
      debugPrint('❌ 添加阅读记录错误: $e');
      rethrow;
    }
  }

  // 获取阅读统计列表
  Future<List<ReadingStat>> getReadingStats({
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/user/reading/stats',
        queryParameters: {
          if (page != null) 'page': page,
          if (pageSize != null) 'page_size': pageSize,
        },
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      final statsList = data['data'] as List;
      return statsList
          .map((json) => ReadingStat.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 获取阅读统计列表错误: $e');
      rethrow;
    }
  }

  // 获取指定小说的阅读统计
  Future<ReadingStat> getNovelReadingStat(String novelId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/user/reading/stats/$novelId',
      );

      final data = response.data;
      if (data == null || data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误',
        );
      }

      return ReadingStat.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ 获取小说阅读统计错误: $e');
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
}
