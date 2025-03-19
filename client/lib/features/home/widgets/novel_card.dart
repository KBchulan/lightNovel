import 'package:flutter/material.dart';
import '../../../core/models/novel.dart';
import '../../../config/app_config.dart';

class NovelCard extends StatelessWidget {
  final Novel novel;
  final VoidCallback onTap;

  const NovelCard({
    Key? key,
    required this.novel,
    required this.onTap,
  }) : super(key: key);

  String? _getCoverUrl() {
    if (novel.cover.isNotEmpty) {
      return novel.cover.startsWith('http') 
          ? novel.cover 
          : '${AppConfig.apiBaseUrl}${novel.cover}';
    }

    // 如果没有封面，使用第一章第一张图片作为封面
    final encodedTitle = Uri.encodeComponent(novel.title);
    return 'http://localhost:8080/novels/$encodedTitle/volume_1/chapter_1/001.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _getCoverUrl();
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 220, // 设置固定高度
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
                    : Image.network(
                        coverUrl,
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
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
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