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
import '../../../shared/widgets/page_transitions.dart';
import '../pages/reading_page.dart';

class ChapterListSheet extends ConsumerStatefulWidget {
  final String novelId;
  final int currentVolumeNumber;
  final int currentChapterNumber;

  const ChapterListSheet({
    super.key,
    required this.novelId,
    required this.currentVolumeNumber,
    required this.currentChapterNumber,
  });

  @override
  ConsumerState<ChapterListSheet> createState() => _ChapterListSheetState();
}

class _ChapterListSheetState extends ConsumerState<ChapterListSheet> {
  final DraggableScrollableController _controller = DraggableScrollableController();
  final Set<int> _expandedVolumes = {};
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _expandedVolumes.add(widget.currentVolumeNumber);
    
    // 预加载当前卷的章节
    Future.microtask(() {
      ref.read(chapterNotifierProvider.notifier).fetchChapters(
            widget.novelId,
            widget.currentVolumeNumber,
          );
    });

    _controller.addListener(_onDragUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onDragUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate() {
    final size = _controller.size;
    if (size >= 0.9 && !_isFullScreen) {
      setState(() => _isFullScreen = true);
    } else if (size < 0.9 && _isFullScreen) {
      setState(() => _isFullScreen = false);
    }
  }

  Future<void> _toggleVolume(int volumeNumber) async {
    if (_expandedVolumes.contains(volumeNumber)) {
      setState(() {
        _expandedVolumes.remove(volumeNumber);
      });
      return;
    }

    if (!ref.read(chapterNotifierProvider.notifier).isCached(widget.novelId, volumeNumber)) {
      await ref.read(chapterNotifierProvider.notifier).fetchChapters(
            widget.novelId,
            volumeNumber,
          );
    }

    setState(() {
      _expandedVolumes.add(volumeNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final volumes = ref.watch(volumeNotifierProvider).value ?? [];
    final chapters = ref.watch(chapterNotifierProvider);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent <= notification.minExtent) {
          Navigator.of(context).pop();
        }
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        controller: _controller,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // 标题区域（作为拖动把手）
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    // 计算新的面板高度
                    final delta = details.primaryDelta! / MediaQuery.of(context).size.height;
                    final newSize = _controller.size - delta;
                    // 确保新的高度在有效范围内
                    if (newSize >= 0.3 && newSize <= 0.95) {
                      _controller.jumpTo(newSize);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Row(
                            children: [
                              Text(
                                '目录',
                                style: theme.textTheme.titleLarge,
                              ),
                              const Spacer(),
                              Text(
                                '第${widget.currentVolumeNumber}卷 第${widget.currentChapterNumber}话',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 分割线
                const Divider(height: 1),
                // 目录列表
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: volumes.length,
                    itemBuilder: (context, index) {
                      final volume = volumes[index];
                      final isExpanded = _expandedVolumes.contains(volume.volumeNumber);
                      final volumeChapters = chapters[volume.volumeNumber] ?? [];

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
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
                                children: volumeChapters.map((chapter) => ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.only(left: 32),
                                      selected: widget.currentVolumeNumber == volume.volumeNumber &&
                                          widget.currentChapterNumber == chapter.chapterNumber,
                                      selectedTileColor: theme.colorScheme.primaryContainer.withAlpha(78),
                                      title: Text(
                                        '第 ${chapter.chapterNumber} 话  ${chapter.title}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: widget.currentVolumeNumber == volume.volumeNumber &&
                                                  widget.currentChapterNumber == chapter.chapterNumber
                                              ? theme.colorScheme.primary
                                              : null,
                                        ),
                                      ),
                                      onTap: () async {
                                        final chapterContent = await ref
                                            .read(volumeNotifierProvider.notifier)
                                            .fetchChapterContent(
                                              widget.novelId,
                                              volume.volumeNumber,
                                              chapter.chapterNumber,
                                            );

                                        if (context.mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            ChapterTransitionRoute(
                                              page: ReadingPage(
                                                chapter: chapterContent,
                                                novelId: widget.novelId,
                                              ),
                                              isNext: chapter.chapterNumber > widget.currentChapterNumber,
                                            ),
                                          );
                                        }
                                      },
                                    )).toList(),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 