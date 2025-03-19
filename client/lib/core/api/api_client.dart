import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/novel.dart';
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

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
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

  Future<void> _onError(DioException err, ErrorInterceptorHandler handler) async {
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
      
      debugPrint('获取到的响应数据: ${response.data}');
      
      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据为空',
        );
      }

      // 处理分页响应
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
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据为空',
        );
      }

      // 处理响应
      if (data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误：缺少 data 字段',
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
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据为空',
        );
      }

      // 处理响应
      if (data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误：缺少 data 字段',
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
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据为空',
        );
      }

      // 处理响应
      if (data['data'] == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: '响应数据格式错误：缺少 data 字段',
        );
      }

      final novelsList = data['data'] as List;
      return novelsList
          .map((json) => Novel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 搜索小说错误: $e');
      rethrow;
    }
  }

  // GET 请求
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  // POST 请求
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  // PUT 请求
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  // DELETE 请求
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }
} 