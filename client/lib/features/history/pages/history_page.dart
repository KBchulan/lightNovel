// ****************************************************************************
//
// @file       history_page.dart
// @brief      历史记录页面
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/models/novel.dart';
import '../../../core/models/read_history.dart';
import '../../../core/models/reading_progress.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/reading_provider.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/widgets/snack_message.dart';
import '../../../shared/props/novel_props.dart';
import '../../novel/pages/novel_detail_page.dart';
import '../../reading/pages/reading_page.dart';
import '../widgets/empty_history.dart';

// 历史记录数据提供者
final historyProvider =
    FutureProvider.autoDispose<List<ReadHistory>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  try {
    final result = await apiClient.getReadHistory();
    
    // 确保历史记录的唯一性，使用 Map 来去重
    final uniqueHistories = <String, ReadHistory>{};
    for (final history in result) {
      uniqueHistories[history.novelId] = history;
    }
    
    // 按最后阅读时间排序
    final sortedHistories = uniqueHistories.values.toList()
      ..sort((a, b) => b.lastRead.compareTo(a.lastRead));
    
    return sortedHistories;
  } catch (e) {
    if (e is DioException && e.error.toString().contains('响应数据格式错误')) {
      return [];
    }
    rethrow;
  }
});

// 添加自动刷新功能
final historyRefreshProvider = StreamProvider.autoDispose<void>((ref) {
  final controller = StreamController<void>();

  ref.listen(readingNotifierProvider, (previous, next) {
    // 当阅读状态发生变化时，刷新历史记录
    controller.add(null);
    ref.invalidate(historyProvider);
  });

  ref.onDispose(() {
    controller.close();
  });

  return controller.stream;
});

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听阅读状态变化
    ref.listen(readingNotifierProvider, (previous, next) {
      // 当阅读状态发生变化时，刷新历史记录
      ref.invalidate(historyProvider);
    });

    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('阅读历史'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空历史',
            onPressed: () {
              _showClearHistoryDialog(context, ref);
            },
          ),
        ],
      ),
      body: historyAsync.when(
        data: (histories) {
          if (histories.isEmpty) {
            return const EmptyHistory();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final history = histories[index];
              return _HistoryItem(
                key: ValueKey('history_${history.id}'),
                history: history,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '加载失败',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showClearHistoryDialog(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空阅读历史'),
        content: const Text('确定要清空所有阅读历史吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final apiClient = ref.read(apiClientProvider);
        // 清空所有历史记录和阅读进度
        await apiClient.clearReadHistory();
        ref.invalidate(historyProvider);
        if (context.mounted) {
          SnackMessage.show(context, '已清空阅读历史');
        }
      } catch (e) {
        if (context.mounted) {
          SnackMessage.show(context, '清空失败: $e', isError: true);
        }
      }
    }
  }
}

class _HistoryItem extends ConsumerStatefulWidget {
  final ReadHistory history;

  const _HistoryItem({
    super.key,
    required this.history,
  });

  @override
  ConsumerState<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends ConsumerState<_HistoryItem> {
  Novel? _novel;
  ReadingProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNovelAndProgress();
  }

  Future<void> _loadNovelAndProgress() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final novel = await apiClient.getNovelDetail(widget.history.novelId);
      final progress = await apiClient.getReadProgress(widget.history.novelId);
      
      if (mounted) {
        setState(() {
          _novel = novel;
          _progress = progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _novel = null;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 152,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    LinearProgressIndicator(),
                    SizedBox(height: 8),
                    LinearProgressIndicator(value: 0.6),
                    SizedBox(height: 8),
                    LinearProgressIndicator(value: 0.3),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_novel == null || _progress == null) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key('history_${widget.history.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除历史记录'),
            content: const Text('确定要删除这条阅读历史吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确定'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (direction) async {
        try {
          final apiClient = ref.read(apiClientProvider);
          // 删除单本小说的历史记录和阅读进度
          await Future.wait([
            apiClient.deleteReadHistory(widget.history.novelId),
            apiClient.deleteReadProgress(widget.history.novelId),
          ]);
          ref.invalidate(historyProvider);
        } catch (e) {
          if (mounted) {
            SnackMessage.show(context, '删除失败: $e', isError: true);
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              SlideUpPageRoute(
                page: NovelDetailPage(novel: _novel!),
              ),
            );
          },
          onLongPress: () => _showOperationMenu(context),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 封面图
                    Hero(
                      tag: 'novel_cover_${widget.history.novelId}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 120,
                          child: NovelProps.buildCoverImage(
                            NovelProps.getCoverUrl(_novel!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 信息区
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _novel!.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _novel!.author,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '第${_progress!.volumeNumber}卷 第${_progress!.chapterNumber}话',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                NovelProps.formatDateTime(
                                    widget.history.lastRead),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 继续阅读按钮
              Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      final chapter =
                          await ref.read(apiClientProvider).getChapterContent(
                                widget.history.novelId,
                                _progress!.volumeNumber,
                                _progress!.chapterNumber,
                              );

                      if (mounted) {
                        Navigator.push(
                          context,
                          SlideUpPageRoute(
                            page: ReadingPage(
                              chapter: chapter,
                              novelId: widget.history.novelId,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        SnackMessage.show(context, '获取章节失败: $e', isError: true);
                      }
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('继续阅读'),
                  style: TextButton.styleFrom(
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOperationMenu(BuildContext context) {
    final BuildContext currentContext = context;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('删除此记录'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: currentContext,
                  builder: (context) => AlertDialog(
                    title: const Text('删除历史记录'),
                    content: const Text('确定要删除这条阅读历史吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  try {
                    final apiClient = ref.read(apiClientProvider);
                    // 删除单本小说的历史记录和阅读进度
                    await Future.wait([
                      apiClient.deleteReadHistory(widget.history.novelId),
                      apiClient.deleteReadProgress(widget.history.novelId),
                    ]);
                    ref.invalidate(historyProvider);
                  } catch (e) {
                    if (mounted) {
                      SnackMessage.show(currentContext, '删除失败: $e',
                          isError: true);
                    }
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('查看详情'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  currentContext,
                  SlideUpPageRoute(
                    page: NovelDetailPage(novel: _novel!),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
