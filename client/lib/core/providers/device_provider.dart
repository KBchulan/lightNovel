import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/device_service.dart';
import 'storage_service_provider.dart';

part 'device_provider.g.dart';

@riverpod
DeviceService deviceService(DeviceServiceRef ref) {
  final storageService = ref.watch(storageServiceProvider);
  return DeviceService(storageService);
} 