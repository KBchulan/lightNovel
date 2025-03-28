// ****************************************************************************
//
// @file       chapter_list_sheet.dart
// @brief      章节目录底部弹出组件
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/volume_provider.dart';
import '../../../core/providers/chapter_provider.dart';
import '../../../core/models/chapter.dart';
import '../../../core/models/chapter_info.dart';
import '../pages/reading_page.dart';
import '../../../shared/animations/page_transitions.dart';
import '../../../shared/animations/animation_manager.dart';

class ChapterListSheet extends ConsumerStatefulWidget {
  final String novelId;
  final Chapter currentChapter;

  const ChapterListSheet({
    super.key,
    required this.novelId,
    required this.currentChapter,
  });

  @override
  ConsumerState<ChapterListSheet> createState() => _ChapterListSheetState();
}

class _ChapterListSheetState extends ConsumerState<ChapterListSheet> {
  final Set<int> _expandedVolumes = {};
  bool _shouldShowAnimation = true;

  @override
  void initState() {
    super.initState();
    // 确保卷数据已加载
    Future.microtask(() async {
      // 检查卷数据是否已加载
      final volumesAsync = ref.read(volumeNotifierProvider);
      if (!volumesAsync.hasValue || volumesAsync.asData?.value.isEmpty == true) {
        await ref.read(volumeNotifierProvider.notifier).fetchVolumes(widget.novelId);
      }
      
      // 预加载当前卷的内容
      final currentVolumeNumber = widget.currentChapter.volumeNumber;
      _toggleVolume(currentVolumeNumber, autoExpand: true);
    });

    // 延迟关闭动画标记，确保动画完整播放一次
    Future.delayed(AnimationManager.longDuration, () {
      if (mounted) {
        setState(() {
          _shouldShowAnimation = false;
        });
      }
    });
  }

  Future<void> _toggleVolume(int volumeNumber,
      {bool autoExpand = false}) async {
    if (!autoExpand && _expandedVolumes.contains(volumeNumber)) {
      setState(() {
        _expandedVolumes.remove(volumeNumber);
      });
      return;
    }

    // 预加载章节
    if (!ref
        .read(chapterNotifierProvider.notifier)
        .isCached(widget.novelId, volumeNumber)) {
      try {
        await ref
            .read(chapterNotifierProvider.notifier)
            .fetchChapters(widget.novelId, volumeNumber);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('加载章节失败')),
          );
        }
        return;
      }
    }

    // 展开卷
    if (mounted) {
      setState(() {
        _expandedVolumes.add(volumeNumber);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final volumesAsync = ref.watch(volumeNotifierProvider);
    final chapterList = ref.watch(chapterNotifierProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // 顶部拖动条
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withAlpha(25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '目录',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: volumesAsync.when(
                  data: (volumes) {
                    if (volumes.isEmpty) {
                      // 尝试重新加载卷数据
                      Future.microtask(() {
                        ref.read(volumeNotifierProvider.notifier).fetchVolumes(widget.novelId);
                      });
                      
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text('正在加载目录数据...', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: volumes.length,
                      itemBuilder: (context, index) {
                        final volume = volumes[index];
                        final isExpanded =
                            _expandedVolumes.contains(volume.volumeNumber);
                        final isCurrentVolume =
                            widget.currentChapter.volumeNumber ==
                                volume.volumeNumber;
                        final volumeChapters =
                            chapterList[volume.volumeNumber] ?? [];

                        return AnimationManager.buildStaggeredListItem(
                          index: index,
                          withAnimation: _shouldShowAnimation,
                          type: AnimationType.slideUp,
                          duration: AnimationManager.mediumDuration,
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 4.0),
                            color: null,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isCurrentVolume
                                    ? theme.colorScheme.primary.withAlpha(60)
                                    : theme.colorScheme.outlineVariant
                                        .withAlpha(78),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // 卷标题
                                ListTile(
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '第 ${volume.volumeNumber} 卷',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isCurrentVolume
                                                ? theme.colorScheme.primary
                                                : null,
                                          ),
                                        ),
                                      ),
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0,
                                        duration:
                                            AnimationManager.shortDuration,
                                        child: Icon(
                                          Icons.keyboard_arrow_down,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: volume.chapterCount > 0
                                      ? Text('共 ${volume.chapterCount} 话')
                                      : null,
                                  onTap: () =>
                                      _toggleVolume(volume.volumeNumber),
                                ),
                                // 章节列表
                                AnimatedCrossFade(
                                  firstChild: Container(),
                                  secondChild: Column(
                                    children: volumeChapters.map((chapter) {
                                      final isCurrentChapter =
                                          chapter.chapterNumber ==
                                                  widget.currentChapter
                                                      .chapterNumber &&
                                              volume.volumeNumber ==
                                                  widget.currentChapter
                                                      .volumeNumber;

                                      return _ChapterListItem(
                                        chapter: chapter,
                                        volumeNumber: volume.volumeNumber,
                                        isCurrentChapter: isCurrentChapter,
                                        novelId: widget.novelId,
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
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('加载出错: $error')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChapterListItem extends ConsumerWidget {
  final ChapterInfo chapter;
  final int volumeNumber;
  final bool isCurrentChapter;
  final String novelId;

  const _ChapterListItem({
    required this.chapter,
    required this.volumeNumber,
    required this.isCurrentChapter,
    required this.novelId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 20.0, right: 16.0),
      title: Text(
        chapter.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isCurrentChapter ? FontWeight.bold : null,
          color: isCurrentChapter
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // 高亮显示当前阅读章节
      tileColor: isCurrentChapter
          ? theme.colorScheme.primaryContainer.withAlpha(52)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () async {
        final loadingChapter =
            await ref.read(volumeNotifierProvider.notifier).fetchChapterContent(
                  novelId,
                  volumeNumber,
                  chapter.chapterNumber,
                );

        if (context.mounted) {
          // 关闭底部弹窗
          Navigator.pop(context);

          // 如果不是当前章节，跳转到对应章节
          if (!isCurrentChapter) {
            Navigator.pushReplacement(
              context,
              SharedAxisPageRoute(
                page: ReadingPage(
                  chapter: loadingChapter,
                  novelId: novelId,
                ),
                type: SharedAxisTransitionType.horizontal,
              ),
            );
          }
        }
      },
    );
  }
}
