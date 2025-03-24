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
import '../../../core/models/reading_progress.dart';
import '../../../shared/props/novel_props.dart';
import '../../../core/providers/volume_provider.dart';
import '../../../core/providers/history_provider.dart';
import '../../../shared/animations/page_transitions.dart';
import '../../../shared/animations/animation_manager.dart';
import '../widgets/novel_share_sheet.dart';
import '../../reading/pages/reading_page.dart';
import '../../../core/providers/api_provider.dart';
import '../../../shared/widgets/snack_message.dart';
import '../../../core/providers/novel_provider.dart';
import '../../../core/providers/chapter_provider.dart';

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
  bool _isLoadingProgress = true;
  ReadingProgress? _readingProgress;
  bool _shouldShowAnimation = true;

  @override
  void initState() {
    super.initState();
    // 加载卷列表和收藏状态
    Future.microtask(() async {
      try {
        await ref
            .read(volumeNotifierProvider.notifier)
            .fetchVolumes(widget.novel.id);
        await _checkFavoriteStatus();
        await _loadReadingProgress();
        // 刷新历史记录
        await ref.read(historyNotifierProvider.notifier).refresh();
      } catch (e) {
        debugPrint('❌ 初始化数据加载错误: $e');
      }
    });
    
    // 延迟关闭动画标记，确保动画完整播放一次
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _shouldShowAnimation = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面重新显示时刷新阅读进度和历史记录
    Future.microtask(() async {
      try {
        await _loadReadingProgress();
        // 刷新历史记录
        await ref.read(historyNotifierProvider.notifier).refresh();
      } catch (e) {
        debugPrint('❌ 页面更新时刷新数据错误: $e');
      }
    });
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorite =
          await ref.read(apiClientProvider).checkFavorite(widget.novel.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackMessage.show(context, '检查收藏状态失败: $e', isError: true);
      }
    }
  }

  Future<void> _loadReadingProgress() async {
    setState(() => _isLoadingProgress = true);
    try {
      // 使用共享的historyProgress provider
      final progressAsync = ref.refresh(historyProgress(widget.novel.id));
      // 正确获取值，不对非Future类型使用await
      final progress = progressAsync.valueOrNull;

      if (mounted) {
        setState(() {
          _readingProgress = progress;
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      debugPrint('❌ 加载进度失败: $e');
      if (mounted) {
        setState(() {
          _readingProgress = null;
          _isLoadingProgress = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await ref.read(apiClientProvider).removeFavorite(widget.novel.id);
        if (mounted) {
          SnackMessage.show(context, '取消收藏了喵');
          // 刷新收藏列表
          ref.read(favoriteNotifierProvider.notifier).fetchFavorites();
        }
      } else {
        await ref.read(apiClientProvider).addFavorite(widget.novel.id);
        if (mounted) {
          SnackMessage.show(context, '添加到收藏了喵');
          // 刷新收藏列表
          ref.read(favoriteNotifierProvider.notifier).fetchFavorites();
        }
      }
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackMessage.show(context, '操作失败: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final volumesAsync = ref.watch(volumeNotifierProvider);
    
    final shouldAnimate = AnimationManager.shouldAnimateAfterDataLoad(
      hasData: volumesAsync.hasValue,
      isLoading: volumesAsync.isLoading || _isLoadingProgress,
      hasError: volumesAsync.hasError,
    ) && _shouldShowAnimation;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _shouldShowAnimation = true;
          });
          
          try {
            await Future.wait([
              ref
                  .read(volumeNotifierProvider.notifier)
                  .fetchVolumes(widget.novel.id),
              _checkFavoriteStatus(),
              _loadReadingProgress(),
              ref.read(historyNotifierProvider.notifier).refresh(),
            ]);
          } catch (e) {
            const errorMsg = '刷新数据失败，请稍后再试';
            if (context.mounted) {
              SnackMessage.show(context, errorMsg, isError: true);
            }
          }
          
          // 延迟关闭动画标记，确保动画完整播放一次
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            setState(() {
              _shouldShowAnimation = false;
            });
          }
        },
        child: CustomScrollView(
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
                      builder: (context) =>
                          NovelShareSheet(novel: widget.novel),
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
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox.expand(
                        child: NovelProps.buildCoverImage(
                          NovelProps.getCoverUrl(widget.novel),
                          fit: BoxFit.cover,
                        ),
                      ),
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
                      AnimationManager.buildAnimatedElement(
                        withAnimation: shouldAnimate,
                        type: AnimationType.slideUp,
                        duration: AnimationManager.shortDuration,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.novel.tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              labelStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 操作按钮
                    AnimationManager.buildAnimatedElement(
                      withAnimation: shouldAnimate,
                      type: AnimationType.slideUp,
                      duration: AnimationManager.normalDuration,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _toggleFavorite,
                              icon: Icon(_isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                              label: Text(_isFavorite ? '已收藏' : '收藏'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isLoadingProgress
                                  ? null
                                  : () async {
                                      if (_readingProgress != null) {
                                        // 继续阅读
                                        final volume = await ref
                                            .read(volumeNotifierProvider.notifier)
                                            .fetchChapterContent(
                                              widget.novel.id,
                                              _readingProgress!.volumeNumber,
                                              _readingProgress!.chapterNumber,
                                            );

                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            SharedAxisPageRoute(
                                              page: ReadingPage(
                                                chapter: volume,
                                                novelId: widget.novel.id,
                                              ),
                                              type: SharedAxisTransitionType
                                                  .horizontal,
                                            ),
                                          );
                                        }
                                      } else {
                                        // 从头开始阅读
                                        final volumesAsync =
                                            ref.read(volumeNotifierProvider);
                                        final volumes = volumesAsync.value;
                                        if (volumes == null || volumes.isEmpty) {
                                          if (context.mounted) {
                                            SnackMessage.show(
                                              context,
                                              '服务器没有这些章节喵',
                                              isError: true,
                                              duration: const Duration(
                                                  milliseconds: 500),
                                            );
                                          }
                                          return;
                                        }

                                        final firstVolume = volumes.first;
                                        final chapters = await ref
                                            .read(volumeNotifierProvider.notifier)
                                            .fetchChapters(
                                              widget.novel.id,
                                              firstVolume.volumeNumber,
                                            );

                                        if (chapters.isEmpty) {
                                          if (context.mounted) {
                                            SnackMessage.show(
                                              context,
                                              '服务器没有这些章节喵',
                                              isError: true,
                                              duration: const Duration(
                                                  milliseconds: 500),
                                            );
                                          }
                                          return;
                                        }

                                        final firstChapterInfo = chapters.first;
                                        final firstChapter = await ref
                                            .read(volumeNotifierProvider.notifier)
                                            .fetchChapterContent(
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
                                              type: SharedAxisTransitionType
                                                  .horizontal,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              icon: Icon(_isLoadingProgress
                                  ? Icons.hourglass_empty
                                  : Icons.book),
                              label: Text(_isLoadingProgress
                                  ? '加载中...'
                                  : (_readingProgress != null ? '继续阅读' : '开始阅读')),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_readingProgress != null && !_isLoadingProgress)
                      AnimationManager.buildAnimatedElement(
                        withAnimation: shouldAnimate,
                        type: AnimationType.fade,
                        duration: AnimationManager.shortDuration,
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '上次读到：第${_readingProgress!.volumeNumber}卷 第${_readingProgress!.chapterNumber}话',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 3)
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 3),

                    // 简介
                    AnimationManager.buildAnimatedElement(
                      withAnimation: shouldAnimate,
                      type: AnimationType.slideUp,
                      duration: AnimationManager.mediumDuration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 目录
                    AnimationManager.buildAnimatedElement(
                      withAnimation: shouldAnimate,
                      type: AnimationType.slideUp,
                      duration: AnimationManager.longDuration,
                      child: Column(
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
                          _VolumeList(
                            novel: widget.novel,
                            shouldShowAnimation: shouldAnimate,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeList extends ConsumerStatefulWidget {
  final Novel novel;
  final bool shouldShowAnimation;

  const _VolumeList({
    required this.novel,
    this.shouldShowAnimation = false,
  });

  @override
  ConsumerState<_VolumeList> createState() => _VolumeListState();
}

class _VolumeListState extends ConsumerState<_VolumeList> {
  final Set<int> _expandedVolumes = {};

  Future<void> _toggleVolume(int volumeNumber) async {
    if (_expandedVolumes.contains(volumeNumber)) {
      setState(() {
        _expandedVolumes.remove(volumeNumber);
      });
      return;
    }

    if (!ref.read(chapterNotifierProvider.notifier).isCached(widget.novel.id, volumeNumber)) {
      await ref.read(chapterNotifierProvider.notifier).fetchChapters(
            widget.novel.id,
            volumeNumber,
          );
    }

    setState(() {
      _expandedVolumes.add(volumeNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final volumesAsync = ref.watch(volumeNotifierProvider);
    final chapters = ref.watch(chapterNotifierProvider);
    final theme = Theme.of(context);

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
            final volumeChapters = chapters[volume.volumeNumber] ?? [];

            return AnimationManager.buildStaggeredListItem(
              index: volumes.indexOf(volume),
              withAnimation: widget.shouldShowAnimation,
              type: AnimationType.slideUp,
              duration: AnimationManager.mediumDuration,
              child: Column(
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
                    trailing: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.5 : 0,
                      child: const Icon(Icons.expand_more),
                    ),
                    onTap: () => _toggleVolume(volume.volumeNumber),
                  ),
                  ClipRect(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      heightFactor: isExpanded ? 1.0 : 0.0,
                      alignment: Alignment.center,
                      curve: Curves.easeInOut,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: volumeChapters.map((chapterInfo) => ListTile(
                              contentPadding: const EdgeInsets.only(left: 32),
                              visualDensity: const VisualDensity(vertical: -4),
                              title: Text(
                                '第 ${chapterInfo.chapterNumber} 话  ${chapterInfo.title}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withAlpha(222),
                                ),
                              ),
                              onTap: () async {
                                // 获取章节内容
                                final chapter = await ref
                                    .read(volumeNotifierProvider.notifier)
                                    .fetchChapterContent(
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
                    ),
                  ),
                ],
              ),
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
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
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
