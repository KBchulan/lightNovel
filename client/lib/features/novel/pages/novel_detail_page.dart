// ****************************************************************************
//
// @file       novel_detail_page.dart
// @brief      小说详情页面
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import '../../../core/models/novel.dart';
import '../../../shared/props/novel_props.dart';

class NovelDetailPage extends StatelessWidget {
  final Novel novel;

  const NovelDetailPage({
    super.key,
    required this.novel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  NovelProps.getCoverImage(
                    novel,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          novel.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          novel.author,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '更新时间：${NovelProps.formatDateTime(novel.updatedAt)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标签
                  if (novel.tags.isNotEmpty) ...[
                    SizedBox(
                      height: 30,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: novel.tags.length,
                        separatorBuilder: (context, index) => 
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return Chip(
                            label: Text(novel.tags[index]),
                            materialTapTargetSize: 
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: 实现收藏功能
                          },
                          icon: const Icon(Icons.favorite_border),
                          label: const Text('收藏'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            // TODO: 实现阅读功能
                          },
                          icon: const Icon(Icons.book),
                          label: const Text('继续阅读'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 简介
                  const Text(
                    '简介',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    novel.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 目录
                  const Text(
                    '目录',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text('共 ${novel.volumeCount} 卷'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: 跳转到目录页面
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 