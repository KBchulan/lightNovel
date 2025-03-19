// ****************************************************************************
//
// @file       storage_service.dart
// @brief      本地存储服务
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_service.g.dart';

class StorageService {
  final Map<String, dynamic> _storage = {};

  Future<void> saveData<T>(String key, T value) async {
    _storage[key] = value;
  }

  Future<T?> getData<T>(String key) async {
    final value = _storage[key];
    if (value != null && value is T) {
      return value;
    }
    return null;
  }

  Future<void> saveStringList(String key, List<String> value) async {
    _storage[key] = List<String>.from(value);
  }

  Future<List<String>> getStringList(String key) async {
    final value = _storage[key];
    if (value is List) {
      return value.cast<String>();
    }
    return [];
  }

  Future<void> remove(String key) async {
    _storage.remove(key);
  }
}

@riverpod
StorageService storageService(StorageServiceRef ref) {
  return StorageService();
}
