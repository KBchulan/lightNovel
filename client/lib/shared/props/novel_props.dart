// ****************************************************************************
//
// @file       novel_props.dart
// @brief      小说相关属性处理工具
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import '../../core/models/novel.dart';
import '../../config/app_config.dart';

class NovelProps {
  static const _imageFormats = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

  static String? getCoverUrl(Novel novel) {
    if (novel.cover.isNotEmpty) {
      return novel.cover.startsWith('http')
          ? novel.cover
          : '${AppConfig.staticUrl}${novel.cover}';
    }

    // 如果没有封面，使用第一章第一张图片作为封面
    final encodedTitle = Uri.encodeComponent(novel.title);
    return '${AppConfig.staticUrl}/novels/$encodedTitle/volume_1/chapter_1/001.${_imageFormats[0]}';
  }

  static Widget buildCoverImage(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (url == null) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.book, size: 48, color: Colors.grey),
      );
    }

    return _NetworkImageWithRetry(
      url: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      imageFormats: _imageFormats,
    );
  }

  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return '连载中';
      case 'completed':
        return '已完结';
      default:
        return status;
    }
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}

class _NetworkImageWithRetry extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final List<String> imageFormats;

  const _NetworkImageWithRetry({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    required this.imageFormats,
  });

  @override
  State<_NetworkImageWithRetry> createState() => _NetworkImageWithRetryState();
}

class _NetworkImageWithRetryState extends State<_NetworkImageWithRetry> {
  late String _currentUrl;
  int _currentFormatIndex = 0;
  bool _hasError = false;
  final _uniqueKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
  }

  @override
  void didUpdateWidget(_NetworkImageWithRetry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _currentUrl = widget.url;
      _currentFormatIndex = 0;
      _hasError = false;
    }
  }

  void _tryNextFormat() {
    if (_currentFormatIndex >= widget.imageFormats.length - 1) {
      setState(() => _hasError = true);
      return;
    }

    _currentFormatIndex++;
    final baseUrl = _currentUrl.substring(0, _currentUrl.lastIndexOf('.'));
    setState(() {
      _currentUrl = '$baseUrl.${widget.imageFormats[_currentFormatIndex]}';
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          );
    }

    return Image.network(
      _currentUrl,
      key: ValueKey('${_currentUrl}_$_uniqueKey'),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.high,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.placeholder ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        _tryNextFormat();
        return widget.placeholder ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
      },
    );
  }
}
