// ****************************************************************************
//
// @file       cached_image.dart
// @brief      缓存图片
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/services/storage_service.dart';

class CachedImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  late Future<Uint8List?> _imageFuture;
  final _storage = StorageService();
  final _dio = Dio();

  @override
  void initState() {
    super.initState();
    _imageFuture = _getImage();
  }

  Future<Uint8List?> _getImage() async {
    // 尝试从缓存获取
    final cached = await _storage.getData<Uint8List>(widget.url);
    if (cached != null) {
      return cached;
    }

    try {
      // 下载图片
      final response = await _dio.get<List<int>>(
        widget.url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data != null) {
        final bytes = Uint8List.fromList(response.data!);
        // 保存到缓存
        await _storage.saveData(widget.url, bytes);
        return bytes;
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder ?? const CircularProgressIndicator();
        }

        if (snapshot.hasError || snapshot.data == null) {
          return widget.errorWidget ?? const Icon(Icons.error);
        }

        return Image.memory(
          snapshot.data!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      },
    );
  }
}
