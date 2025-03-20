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
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1.0,
              collapseMode: CollapseMode.parallax,
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
                          Colors.black.withAlpha(179),
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
                  _ExpandableDescription(
                    description: novel.description,
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

class _ExpandableDescription extends StatefulWidget {
  final String description;

  const _ExpandableDescription({
    required this.description,
  });

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;
  static const _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.description,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
          maxLines: _isExpanded ? null : _maxLines,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
        if (widget.description.length > 100) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isExpanded ? '收起' : '展开',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Theme.of(context).primaryColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
} 