import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/storage_service.dart';

part 'storage_service_provider.g.dart';

@riverpod
StorageService storageService(StorageServiceRef ref) {
  return StorageService();
} 