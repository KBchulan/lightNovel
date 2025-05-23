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
  bool _isDataLoaded = false;
  ReadingProgress? _readingProgress;
  bool _shouldShowAnimation = true;

  @override
  void initState() {
    super.initState();
    _shouldShowAnimation = true;
    
    Future.microtask(() => _loadAllData());
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _shouldShowAnimation = false;
        });
      }
    });
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoadingProgress = true;
      _shouldShowAnimation = true;
    });
    
    try {
      await _checkFavoriteStatus();
      await _loadReadingProgress();
      
      await Future.microtask(() async {
        await ref.read(historyNotifierProvider.notifier).refresh();
      });
      
      // 最后加载卷数据
      await Future.microtask(() async {
        await ref.read(volumeNotifierProvider.notifier).fetchVolumes(widget.novel.id);
      });
      
      // 额外检查卷数据是否确实已加载
      final volumesAsync = ref.read(volumeNotifierProvider);
      final hasVolumes = volumesAsync.hasValue && !volumesAsync.isLoading;
      
      if (mounted) {
        setState(() {
          _isDataLoaded = hasVolumes;
          
          if (!hasVolumes) {
            debugPrint('⚠️ 卷数据未能正确加载，尝试再次获取...');
            Future.microtask(() async {
              await ref.read(volumeNotifierProvider.notifier).fetchVolumes(widget.novel.id);
              if (mounted) {
                setState(() {
                  _isDataLoaded = true;
                  _shouldShowAnimation = true;
                  
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) {
                      setState(() {
                        _shouldShowAnimation = false;
                      });
                    }
                  });
                });
              }
            });
          } else {
            _shouldShowAnimation = true;
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                setState(() {
                  _shouldShowAnimation = false;
                });
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('❌ 初始化数据加载错误: $e');
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
          _shouldShowAnimation = true;
          
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() {
                _shouldShowAnimation = false;
              });
            }
          });
        });
      }
    }
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

  Future<bool> _checkFavoriteStatus() async {
    try {
      final isFavorite =
          await ref.read(apiClientProvider).checkFavorite(widget.novel.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
      return isFavorite;
    } catch (e) {
      if (mounted) {
        SnackMessage.show(context, '检查收藏状态失败: $e', isError: true);
      }
      rethrow;
    }
  }

  Future<ReadingProgress?> _loadReadingProgress() async {
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
      return progress;
    } catch (e) {
      debugPrint('❌ 加载进度失败: $e');
      if (mounted) {
        setState(() {
          _readingProgress = null;
          _isLoadingProgress = false;
        });
      }
      rethrow;
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

  // 添加一个简介格式化工具函数
  String _formatDescription(String description) {
    // 分割段落
    List<String> paragraphs = description.split('\n').where((p) => p.trim().isNotEmpty).toList();
    
    // 为每段添加两个全角空格作为首行缩进
    return paragraphs.map((p) => '　　${p.trim()}').join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final volumesAsync = ref.watch(volumeNotifierProvider);
    final theme = Theme.of(context);
    
    final historyChange = ref.watch(historyChangeNotifierProvider);
    final deletedNovelId = historyChange['deletedNovelId'] as String?;
    
    if (deletedNovelId == widget.novel.id && _readingProgress != null) {
      _readingProgress = null;
    } else if (deletedNovelId == null) {
      ref.listen(historyProgress(widget.novel.id), (previous, next) {
        if (next.hasValue && next.value != _readingProgress) {
          if (mounted) {
            setState(() {
              _readingProgress = next.value;
            });
          }
        }
      });
    }
    
    final contentReady = volumesAsync.hasValue && _isDataLoaded && !volumesAsync.isLoading && !_isLoadingProgress;
    
    final shouldAnimate = AnimationManager.shouldAnimateAfterDataLoad(
      hasData: volumesAsync.hasValue && _isDataLoaded,
      isLoading: volumesAsync.isLoading || _isLoadingProgress || !_isDataLoaded,
      hasError: volumesAsync.hasError,
    ) && _shouldShowAnimation && contentReady;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // 创建一个渐变过渡的效果
          setState(() {
            _shouldShowAnimation = true;
          });
          
          // 不直接设置_isDataLoaded为false，而是使用透明度过渡
          await _loadAllData();
        },
        child: AnimatedOpacity(
          opacity: contentReady ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          // 主内容
          child: Stack(
            children: [
              CustomScrollView(
                physics: !_isDataLoaded ? const NeverScrollableScrollPhysics() : null,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标签
                          if (widget.novel.tags.isNotEmpty) ...[
                            AnimationManager.buildAnimatedElement(
                              withAnimation: shouldAnimate,
                              type: AnimationType.fade,
                              duration: AnimationManager.shortDuration,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.novel.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withAlpha(38),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 操作按钮
                          AnimationManager.buildAnimatedElement(
                            withAnimation: shouldAnimate,
                            type: AnimationType.fade,
                            duration: AnimationManager.normalDuration,
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isDataLoaded ? _toggleFavorite : null,
                                    icon: Icon(_isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                       color: _isFavorite 
                                           ? theme.colorScheme.primary
                                           : null),
                                    label: Text(_isFavorite ? '已收藏' : '收藏'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _isDataLoaded && !_isLoadingProgress
                                        ? () async {
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
                                                  FadePageRoute(
                                                    page: ReadingPage(
                                                      chapter: volume,
                                                      novelId: widget.novel.id,
                                                    ),
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
                                                  FadePageRoute(
                                                    page: ReadingPage(
                                                      chapter: firstChapter,
                                                      novelId: widget.novel.id,
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        : null,
                                    icon: Icon(_isLoadingProgress
                                        ? Icons.hourglass_empty
                                        : Icons.book),
                                    label: Text(_isLoadingProgress
                                        ? '加载中...'
                                        : (_readingProgress != null ? '继续阅读' : '开始阅读')),
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_readingProgress != null && !_isLoadingProgress && _isDataLoaded)
                            AnimationManager.buildAnimatedElement(
                              withAnimation: shouldAnimate,
                              type: AnimationType.fade,
                              duration: AnimationManager.shortDuration,
                              child: Container(
                                width: double.infinity,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bookmark,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final params = ChapterTitleParams(
                                          novelId: widget.novel.id,
                                          volumeNumber: _readingProgress!.volumeNumber,
                                          chapterNumber: _readingProgress!.chapterNumber,
                                        );
                                        
                                        final titleAsync = ref.watch(chapterTitleProvider(params));
                                        
                                        return Text(
                                          titleAsync.when(
                                            data: (title) => '上次读到：第${_readingProgress!.volumeNumber}卷 $title',
                                            loading: () => '上次读到：第${_readingProgress!.volumeNumber}卷 第${_readingProgress!.chapterNumber}话',
                                            error: (_, __) => '上次读到：第${_readingProgress!.volumeNumber}卷 第${_readingProgress!.chapterNumber}话',
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: theme.colorScheme.primary,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),

                          // 简介
                          AnimationManager.buildAnimatedElement(
                            withAnimation: shouldAnimate,
                            type: AnimationType.fade,
                            duration: AnimationManager.mediumDuration,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '简介',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _ExpandableDescription(
                                  description: _formatDescription(widget.novel.description),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 目录
                          AnimationManager.buildAnimatedElement(
                            withAnimation: shouldAnimate,
                            type: AnimationType.fade,
                            duration: AnimationManager.mediumDuration,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '目录',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _VolumeList(
                                  novel: widget.novel,
                                  shouldShowAnimation: shouldAnimate,
                                  currentReading: _readingProgress,
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
              
              // 加载状态指示器覆盖层 - 使用淡入淡出效果
              AnimatedOpacity(
                opacity: (!contentReady) ? 0.7 : 0.0,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
                child: !contentReady ? Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withAlpha(231),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '正在刷新...',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ) : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolumeList extends ConsumerStatefulWidget {
  final Novel novel;
  final bool shouldShowAnimation;
  final ReadingProgress? currentReading;

  const _VolumeList({
    required this.novel,
    this.shouldShowAnimation = false,
    this.currentReading,
  });

  @override
  ConsumerState<_VolumeList> createState() => _VolumeListState();
}

class _VolumeListState extends ConsumerState<_VolumeList> {
  final Set<int> _expandedVolumes = {};
  // bool _initialExpansionDone = false;

  @override
  void initState() {
    super.initState();
    // 初始化时不直接设置，而是在数据加载后处理
  }

  @override
  void didUpdateWidget(_VolumeList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 自动展开上次阅读卷的功能
    /*
    final volumesAsync = ref.read(volumeNotifierProvider);
    if (volumesAsync.hasValue && 
        widget.currentReading != null && 
        !_initialExpansionDone) {
      _initialExpansionDone = true;
      
      Future.microtask(() {
        if (mounted) {
          _expandVolume(widget.currentReading!.volumeNumber);
        }
      });
    }
    */
  }

  // 加载章节并展开卷
  Future<void> _expandVolume(int volumeNumber) async {
    if (!ref.read(chapterNotifierProvider.notifier).isCached(widget.novel.id, volumeNumber)) {
      await ref.read(chapterNotifierProvider.notifier).fetchChapters(
            widget.novel.id,
            volumeNumber,
          );
    }

    if (mounted) {
      setState(() {
        _expandedVolumes.add(volumeNumber);
      });
    }
  }

  Future<void> _toggleVolume(int volumeNumber) async {
    if (_expandedVolumes.contains(volumeNumber)) {
      setState(() {
        _expandedVolumes.remove(volumeNumber);
      });
      return;
    }

    await _expandVolume(volumeNumber);
  }

  @override
  Widget build(BuildContext context) {
    final volumesAsync = ref.watch(volumeNotifierProvider);
    final chapters = ref.watch(chapterNotifierProvider);
    final theme = Theme.of(context);

    // 添加数据检查，防止显示空数据
    if (volumesAsync.isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (volumesAsync.hasError) {
      return SizedBox(
        height: 40,
        child: Center(
          child: Text('加载失败: ${volumesAsync.error.toString()}'),
        ),
      );
    }
    
    // 确保volumes有值，否则尝试刷新
    if (!volumesAsync.hasValue || volumesAsync.value == null || volumesAsync.value!.isEmpty) {
      // 如果没有数据，尝试重新加载
      Future.microtask(() {
        ref.read(volumeNotifierProvider.notifier).fetchVolumes(widget.novel.id);
      });
      
      return const SizedBox(
        height: 40,
        child: Center(
          child: Text('正在加载卷列表...'),
        ),
      );
    }
    
    final volumes = volumesAsync.value!;
    
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
        final isCurrentVolume = widget.currentReading != null && 
                               widget.currentReading!.volumeNumber == volume.volumeNumber;

        return AnimationManager.buildStaggeredListItem(
          index: volumes.indexOf(volume),
          withAnimation: widget.shouldShowAnimation,
          type: AnimationType.fade,
          duration: AnimationManager.mediumDuration,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            color: null,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(
                color: isCurrentVolume
                    ? theme.colorScheme.primary.withAlpha(60)
                    : theme.colorScheme.outlineVariant.withAlpha(78),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 卷标题
                ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '第 ${volume.volumeNumber} 卷',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCurrentVolume
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            if (isCurrentVolume) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.bookmark,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text('共 ${volume.chapterCount} 话'),
                  onTap: () => _toggleVolume(volume.volumeNumber),
                ),
                // 章节列表
                AnimatedCrossFade(
                  firstChild: Container(),
                  secondChild: Column(
                    children: volumeChapters.map((chapterInfo) {
                      final isCurrentChapter = widget.currentReading != null &&
                          widget.currentReading!.volumeNumber == volume.volumeNumber &&
                          widget.currentReading!.chapterNumber == chapterInfo.chapterNumber;
                          
                      return ListTile(
                        contentPadding: const EdgeInsets.only(left: 32, right: 16),
                        visualDensity: const VisualDensity(vertical: -4),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                chapterInfo.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrentChapter
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withAlpha(222),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentChapter)
                              Icon(
                                Icons.bookmark,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                        tileColor: isCurrentChapter
                            ? theme.colorScheme.primaryContainer.withAlpha(30)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
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
                              FadePageRoute(
                                page: ReadingPage(
                                  chapter: chapter,
                                  novelId: widget.novel.id,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: AnimationManager.shortDuration,
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.description,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: theme.colorScheme.onSurface.withAlpha(231),
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
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.primary,
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