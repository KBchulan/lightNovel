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
import 'dart:io';
import 'storage_service.dart';

part 'device_service.g.dart';

class DeviceService {
  static const String _deviceIdKey = 'device_id';
  static const String _deviceIdFileName = 'device_id.txt';
  final StorageService _storage;
  String? _cachedDeviceId;

  DeviceService(this._storage);

  Future<String> getDeviceId() async {
    // 检查内存缓存
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    // 检查文件存储
    final fileId = await _readDeviceIdFromFile();
    if (fileId != null) {
      _cachedDeviceId = fileId;
      return fileId;
    }

    // 检查持久化存储
    String? deviceId = await _storage.getData<String>(_deviceIdKey);
    if (deviceId != null) {
      _cachedDeviceId = deviceId;
      await _writeDeviceIdToFile(deviceId); // 同步到文件
      return deviceId;
    }

    // 生成新的UUID
    deviceId = const Uuid().v4();
    _cachedDeviceId = deviceId;
    await _storage.saveData(_deviceIdKey, deviceId);
    await _writeDeviceIdToFile(deviceId);
    return deviceId;
  }

  Future<String?> _readDeviceIdFromFile() async {
    try {
      final directory = await _getApplicationDocumentsDirectory();
      debugPrint('📁 尝试读取设备ID文件,目录: ${directory.path}');
      final file = File('${directory.path}/$_deviceIdFileName');
      
      if (await file.exists()) {
        debugPrint('📄 设备ID文件存在,正在读取...');
        final content = await file.readAsString();
        // 提取UUID（跳过注释行）
        final lines = content.split('\n');
        for (final line in lines) {
          if (!line.startsWith('//') && line.trim().isNotEmpty) {
            debugPrint('✅ 成功读取设备ID: ${line.trim()}');
            return line.trim();
          }
        }
      } else {
        debugPrint('❌ 设备ID文件不存在');
      }
    } catch (e) {
      debugPrint('❌ 读取设备ID文件失败: $e');
    }
    return null;
  }

  Future<void> _writeDeviceIdToFile(String deviceId) async {
    try {
      final directory = await _getApplicationDocumentsDirectory();
      debugPrint('📁 尝试写入设备ID文件，目录: ${directory.path}');
      final file = File('${directory.path}/$_deviceIdFileName');
      
      final content = '''// 设备ID文件
// 此文件用于存储设备的唯一标识符
// 请勿手动修改或删除此文件
$deviceId''';
      
      await file.writeAsString(content);
      debugPrint('✅ 成功写入设备ID: $deviceId');
    } catch (e) {
      debugPrint('❌ 写入设备ID文件失败: $e');
    }
  }

  Future<Directory> _getApplicationDocumentsDirectory() async {
    if (Platform.isAndroid) {
      // Android 使用应用私有目录
      final directory = Directory('/data/data/com.example.client/app_flutter');
      debugPrint('📁 使用Android应用私有目录: ${directory.path}');
      if (!await directory.exists()) {
        debugPrint('📁 目录不存在，正在创建...');
        await directory.create(recursive: true);
        debugPrint('✅ 目录创建成功');
      }
      return directory;
    } else if (Platform.isIOS) {
      // iOS 使用应用文档目录
      final directory = Directory('${Platform.environment['HOME']}/Documents');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } else if (Platform.isWindows) {
      final directory = Directory('${Platform.environment['APPDATA']}\\LightNovel');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } else if (Platform.isMacOS) {
      final directory = Directory('${Platform.environment['HOME']}/Library/Application Support/LightNovel');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } else if (Platform.isLinux) {
      final directory = Directory('${Platform.environment['HOME']}/.local/share/light_novel');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }
    throw UnsupportedError('不支持的操作系统');
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
