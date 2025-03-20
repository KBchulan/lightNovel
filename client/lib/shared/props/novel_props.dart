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

    // 如果没有封面，尝试使用第一章第一张图片作为封面
    final encodedTitle = Uri.encodeComponent(novel.title);
    return '${AppConfig.staticUrl}/novels/$encodedTitle/volume_1/chapter_1/001.${_imageFormats[0]}';
  }

  static Widget getCoverImage(Novel novel, {double? width, double? height}) {
    return _CoverImage(
      novel: novel,
      width: width,
      height: height,
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

class _CoverImage extends StatefulWidget {
  final Novel novel;
  final double? width;
  final double? height;

  const _CoverImage({
    required this.novel,
    this.width,
    this.height,
  });

  @override
  State<_CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<_CoverImage> {
  late String _currentUrl;
  int _currentFormatIndex = 0;
  bool _hasError = false;
  final _uniqueKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentUrl = NovelProps.getCoverUrl(widget.novel) ?? '';
  }

  @override
  void didUpdateWidget(_CoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.novel != widget.novel) {
      _currentUrl = NovelProps.getCoverUrl(widget.novel) ?? '';
      _currentFormatIndex = 0;
      _hasError = false;
    }
  }

  void _tryNextFormat() {
    if (_currentFormatIndex >= NovelProps._imageFormats.length - 1) {
      setState(() => _hasError = true);
      return;
    }

    _currentFormatIndex++;
    final baseUrl = _currentUrl.substring(0, _currentUrl.lastIndexOf('.'));
    setState(() {
      _currentUrl = '$baseUrl.${NovelProps._imageFormats[_currentFormatIndex]}';
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUrl.isEmpty || _hasError) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: const Icon(
          Icons.book,
          size: 48,
          color: Colors.grey,
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: Image.network(
        _currentUrl,
        key: ValueKey('${_currentUrl}_$_uniqueKey'),
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          _tryNextFormat();
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
} 