// ****************************************************************************
//
// @file       novel_card.dart
// @brief      通用小说卡片组件
//
// @author     KBchulan
// @date       2025/03/19
// @history    
// ****************************************************************************

import 'package:flutter/material.dart';
import '../../core/models/novel.dart';
import '../../config/app_config.dart';

class NovelCard extends StatelessWidget {
  final Novel novel;
  final VoidCallback onTap;

  const NovelCard({
    super.key,
    required this.novel,
    required this.onTap,
  });

  String? _getCoverUrl() {
    if (novel.cover.isNotEmpty) {
      return novel.cover.startsWith('http')
          ? novel.cover
          : '${AppConfig.apiBaseUrl}${novel.cover}';
    }

    // 如果没有封面，尝试使用第一章第一张图片作为封面
    final encodedTitle = Uri.encodeComponent(novel.title);
    const formats = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
    return 'http://localhost:8080/novels/$encodedTitle/volume_1/chapter_1/001.${formats[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _getCoverUrl();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 220,
          child: Column(
            children: [
              Expanded(
                flex: 4,
                child: coverUrl == null
                    ? Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.book,
                          size: 48,
                          color: Colors.grey,
                        ),
                      )
                    : _CoverImage(coverUrl: coverUrl),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        novel.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (novel.author.isNotEmpty)
                        Text(
                          novel.author,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverImage extends StatefulWidget {
  final String initialUrl;

  const _CoverImage({
    required String coverUrl,
  }) : initialUrl = coverUrl;

  @override
  State<_CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<_CoverImage> {
  late String _currentUrl;
  int _currentFormatIndex = 0;
  bool _hasError = false;
  static const _formats = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
  }

  void _tryNextFormat() {
    if (_currentFormatIndex >= _formats.length - 1) {
      setState(() => _hasError = true);
      return;
    }

    _currentFormatIndex++;
    final baseUrl = _currentUrl.substring(0, _currentUrl.lastIndexOf('.'));
    setState(() {
      _currentUrl = '$baseUrl.${_formats[_currentFormatIndex]}';
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.broken_image,
          size: 48,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      _currentUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        _tryNextFormat();
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
} 