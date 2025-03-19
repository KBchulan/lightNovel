// ****************************************************************************
//
// @file       device_service.dart
// @brief      设备服务
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';

part 'device_service.g.dart';

class DeviceService {
  static const String _deviceIdKey = 'device_id';
  final StorageService _storage;

  DeviceService(this._storage);

  Future<String> getDeviceId() async {
    // 先从本地存储获取
    String? deviceId = await _storage.getData<String>(_deviceIdKey);

    if (deviceId != null) {
      return deviceId;
    }

    // 生成新的UUID作为设备ID
    deviceId = const Uuid().v4();

    // 保存到本地存储
    await _storage.saveData(_deviceIdKey, deviceId);
    return deviceId;
  }

  // 获取设备类型
  String getDeviceType(BuildContext context) {
    if (MediaQuery.of(context).size.shortestSide < 600) {
      return 'mobile';
    }
    return 'tablet';
  }

  // 获取设备基本信息
  Map<String, dynamic> getDeviceInfo(BuildContext context) {
    final window = View.of(context).platformDispatcher;
    return {
      'platform': Theme.of(context).platform.toString(),
      'screenWidth': MediaQuery.of(context).size.width,
      'screenHeight': MediaQuery.of(context).size.height,
      'pixelRatio': MediaQuery.of(context).devicePixelRatio,
      'brightness': window.platformBrightness.toString(),
    };
  }
}

@riverpod
DeviceService deviceService(Ref ref) {
  final storage = ref.watch(storageServiceProvider);
  return DeviceService(storage);
}
