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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/novel.dart';
import '../../../core/models/chapter_info.dart';
import '../../../shared/props/novel_props.dart';
import '../../../core/providers/volume_provider.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../widgets/novel_share_sheet.dart';
import '../../reading/pages/reading_page.dart';
import '../../../core/providers/api_provider.dart';

class NovelDetailPage extends ConsumerStatefulWidget {
  final Novel novel;

  const NovelDetailPage({
    super.key,
    required this.novel,
  });

  @override
  ConsumerState<NovelDetailPage> createState() => _NovelDetailPageState();
}

class _NovelDetailPageState extends ConsumerState<NovelDetailPage> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    // 加载卷列表
    Future.microtask(() {
      ref.read(volumeNotifierProvider.notifier).fetchVolumes(widget.novel.id);
      // 检查收藏状态
      _checkFavoriteStatus();
    });
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorite = await ref.read(apiClientProvider).checkFavorite(widget.novel.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, '检查收藏状态失败: $e', isError: true);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await ref.read(apiClientProvider).removeFavorite(widget.novel.id);
        if (mounted) {
          _showSnackBar(context, '已取消收藏');
        }
      } else {
        await ref.read(apiClientProvider).addFavorite(widget.novel.id);
        if (mounted) {
          _showSnackBar(context, '添加到收藏了喵');
        }
      }
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, '操作失败: $e', isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: theme.colorScheme.onInverseSurface.withAlpha(31),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: theme.colorScheme.onInverseSurface,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError 
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.inverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    transitionAnimationController: AnimationController(
                      vsync: Navigator.of(context),
                      duration: const Duration(milliseconds: 300),
                    ),
                    builder: (context) => NovelShareSheet(novel: widget.novel),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1.0,
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  NovelProps.getCoverImage(
                    widget.novel,
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
                          widget.novel.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.novel.author,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '更新时间：${NovelProps.formatDateTime(widget.novel.updatedAt)}',
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
                  if (widget.novel.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.novel.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleFavorite,
                          icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                          label: Text(_isFavorite ? '已收藏' : '收藏'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            // 获取第一章
                            final volumesAsync = ref.read(volumeNotifierProvider);
                            final volumes = volumesAsync.value;
                            if (volumes == null || volumes.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('服务器没有这些章节喵')),
                                );
                              }
                              return;
                            }

                            // 获取第一卷的第一章
                            final firstVolume = volumes.first;
                            final chapters = await ref.read(volumeNotifierProvider.notifier).fetchChapters(
                              widget.novel.id,
                              firstVolume.volumeNumber,
                            );

                            if (chapters.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('服务器没有这些章节喵')),
                                );
                              }
                              return;
                            }

                            final firstChapterInfo = chapters.first;
                            final firstChapter = await ref.read(volumeNotifierProvider.notifier).fetchChapterContent(
                              widget.novel.id,
                              firstVolume.volumeNumber,
                              firstChapterInfo.chapterNumber,
                            );

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                SharedAxisPageRoute(
                                  page: ReadingPage(
                                    chapter: firstChapter,
                                    novelId: widget.novel.id,
                                  ),
                                  type: SharedAxisTransitionType.horizontal,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.book),
                          label: const Text('开始阅读'),
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
                    description: widget.novel.description,
                  ),
                  const SizedBox(height: 16),

                  // 目录
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '目录',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _VolumeList(novel: widget.novel),
                    ],
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

class _VolumeList extends ConsumerStatefulWidget {
  final Novel novel;

  const _VolumeList({
    required this.novel,
  });

  @override
  ConsumerState<_VolumeList> createState() => _VolumeListState();
}

class _VolumeListState extends ConsumerState<_VolumeList> {
  final Map<int, List<ChapterInfo>> _chapters = {};
  final Set<int> _expandedVolumes = {};

  Future<void> _toggleVolume(int volumeNumber) async {
    if (_expandedVolumes.contains(volumeNumber)) {
      setState(() {
        _expandedVolumes.remove(volumeNumber);
      });
      return;
    }

    if (!_chapters.containsKey(volumeNumber)) {
      final chapters = await ref.read(volumeNotifierProvider.notifier).fetchChapters(
        widget.novel.id,
        volumeNumber,
      );
      setState(() {
        _chapters[volumeNumber] = chapters;
      });
    }

    setState(() {
      _expandedVolumes.add(volumeNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final volumesAsync = ref.watch(volumeNotifierProvider);

    return volumesAsync.when(
      data: (volumes) {
        if (volumes.isEmpty) {
          return const SizedBox(
            height: 40,
            child: Center(
              child: Text('暂无卷'),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: volumes.map((volume) {
            final isExpanded = _expandedVolumes.contains(volume.volumeNumber);
            final chapters = _chapters[volume.volumeNumber] ?? [];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: const VisualDensity(vertical: -4),
                  title: Text(
                    '第 ${volume.volumeNumber} 卷',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text('共 ${volume.chapterCount} 话'),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () => _toggleVolume(volume.volumeNumber),
                ),
                if (isExpanded)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: chapters.map((chapterInfo) => ListTile(
                      contentPadding: const EdgeInsets.only(left: 16),
                      visualDensity: const VisualDensity(vertical: -4),
                      title: Text(
                        '第 ${chapterInfo.chapterNumber} 话 ${chapterInfo.title}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      onTap: () async {
                        // 获取章节内容
                        final chapter = await ref.read(volumeNotifierProvider.notifier).fetchChapterContent(
                          widget.novel.id,
                          volume.volumeNumber,
                          chapterInfo.chapterNumber,
                        );

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            SharedAxisPageRoute(
                              page: ReadingPage(
                                chapter: chapter,
                                novelId: widget.novel.id,
                              ),
                              type: SharedAxisTransitionType.horizontal,
                            ),
                          );
                        }
                      },
                    )).toList(),
                  ),
              ],
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => SizedBox(
        height: 40,
        child: Center(
          child: Text('加载失败: ${error.toString()}'),
        ),
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