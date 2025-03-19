// ****************************************************************************
//
// @file       device_provider.dart
// @brief      提供给其他文件设备信息
//
// @author     KBchulan
// @date       2025/03/19
// @history    
// ****************************************************************************


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/device_service.dart';
import 'storage_service_provider.dart';

part 'device_provider.g.dart';

@riverpod
DeviceService deviceService(Ref ref) {
  final storageService = ref.watch(storageServiceProvider);
  return DeviceService(storageService);
}
