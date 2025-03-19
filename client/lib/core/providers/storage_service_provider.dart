// ****************************************************************************
//
// @file       storage_service_provider.dart
// @brief      提供给其他文件存储服务
//
// @author     KBchulan
// @date       2025/03/19
// @history    
// ****************************************************************************

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/storage_service.dart';

part 'storage_service_provider.g.dart';

@riverpod
StorageService storageService(Ref ref) {
  return StorageService();
}
