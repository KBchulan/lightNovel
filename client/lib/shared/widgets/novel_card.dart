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
import '../props/novel_props.dart';

class NovelCard extends StatelessWidget {
  final Novel novel;
  final VoidCallback onTap;

  const NovelCard({
    super.key,
    required this.novel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = NovelProps.getCoverUrl(novel);

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
                child: NovelProps.buildCoverImage(
                  coverUrl,
                  fit: BoxFit.contain,
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
