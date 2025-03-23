// ****************************************************************************
//
// @file       api_provider.dart
// @brief      API 相关的 Provider
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/api_client.dart';
import '../services/device_service.dart';

part 'api_provider.g.dart';

@riverpod
ApiClient apiClient(Ref ref) {
  final deviceService = ref.watch(deviceServiceProvider);
  return ApiClient(deviceService);
}
