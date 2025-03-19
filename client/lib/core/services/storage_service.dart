// ****************************************************************************
//
// @file       storage_service.dart
// @brief      缓存服务
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'dart:convert';
import 'dart:io';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // 内存缓存
  final Map<String, dynamic> _memoryCache = {};

  // 获取应用文档目录
  Future<String> get _localPath async {
    final directory = await Directory.systemTemp.createTemp('app_storage');
    return directory.path;
  }

  // 获取存储文件
  Future<File> _getFile(String key) async {
    final path = await _localPath;
    return File('$path/$key.json');
  }

  // 保存数据
  Future<void> saveData(String key, dynamic value) async {
    // 保存到内存缓存
    _memoryCache[key] = value;

    // 保存到文件
    final file = await _getFile(key);
    final data = json.encode(value);
    await file.writeAsString(data);
  }

  // 读取数据
  Future<T?> getData<T>(String key) async {
    // 先从内存缓存读取
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key] as T;
    }

    try {
      final file = await _getFile(key);
      if (await file.exists()) {
        final data = await file.readAsString();
        final value = json.decode(data);
        _memoryCache[key] = value;
        return value as T;
      }
    } catch (e) {
      print('Error reading data: $e');
    }
    return null;
  }

  // 删除数据
  Future<void> removeData(String key) async {
    // 从内存缓存删除
    _memoryCache.remove(key);

    // 从文件删除
    try {
      final file = await _getFile(key);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error removing data: $e');
    }
  }

  // 清除所有数据
  Future<void> clearAll() async {
    // 清除内存缓存
    _memoryCache.clear();

    // 清除文件
    try {
      final path = await _localPath;
      final directory = Directory(path);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
}
