// ****************************************************************************
//
// @file       history_page.dart
// @brief      历史记录页面
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/novel.dart';
import '../../../core/models/read_history.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/providers/api_provider.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/widgets/snack_message.dart';
import '../../../shared/props/novel_props.dart';
import '../../novel/pages/novel_detail_page.dart';
import '../../reading/pages/reading_page.dart';
import '../widgets/empty_history.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyNotifierProvider);

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
      body: RefreshIndicator(
        onRefresh: () => ref.read(historyNotifierProvider.notifier).refresh(),
        child: historyAsync.when(
          data: (histories) {
            if (histories.isEmpty) {
              return Stack(
                children: [
                  const EmptyHistory(),
                  // 添加一个可拉动区域以触发RefreshIndicator
                  ListView(),
                ],
              );
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
          error: (error, stack) => Stack(
            children: [
              Center(
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
              // 添加一个可拉动区域以触发RefreshIndicator
              ListView(),
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
        await ref.read(historyNotifierProvider.notifier).clearHistory();
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

class _HistoryItem extends ConsumerWidget {
  final ReadHistory history;

  const _HistoryItem({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用新的provider获取小说和进度信息
    final novelAsync = ref.watch(historyNovelProvider(history.novelId));
    final progressAsync = ref.watch(historyProgress(history.novelId));

    // 检查是否正在加载
    final isLoading = novelAsync.isLoading || progressAsync.isLoading;
    // 检查是否加载出错
    final hasError = novelAsync.hasError || progressAsync.hasError;
    // 获取数据
    final novel = novelAsync.valueOrNull;
    final progress = progressAsync.valueOrNull;

    if (isLoading) {
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

    if (hasError || novel == null || progress == null) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key('history_${history.id}'),
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
        final currentContext = context;
        try {
          await ref.read(historyNotifierProvider.notifier).deleteHistory(history.novelId);
        } catch (e) {
          if (currentContext.mounted) {
            SnackMessage.show(currentContext, '删除失败: $e', isError: true);
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: () {
            final currentContext = context;
            Navigator.push(
              currentContext,
              SlideUpPageRoute(
                page: NovelDetailPage(novel: novel),
              ),
            ).then((_) {
              // 从详情页返回后刷新历史列表
              final historyResult = ref.refresh(historyNotifierProvider);
              // 刷新小说进度
              final progressResult = ref.refresh(historyProgress(history.novelId));
              // 使用刷新结果避免编译器警告
              debugPrint('刷新历史: ${historyResult.hasValue}, 进度: ${progressResult.hasValue}');
            });
          },
          onLongPress: () => _showOperationMenu(context, ref, novel),
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
                      tag: 'novel_cover_${history.novelId}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 120,
                          child: NovelProps.buildCoverImage(
                            NovelProps.getCoverUrl(novel),
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
                            novel.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            novel.author,
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
                              '第${progress.volumeNumber}卷 第${progress.chapterNumber}话',
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
                                    history.lastRead),
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
                    final currentContext = context;
                    try {
                      final chapter =
                          await ref.read(apiClientProvider).getChapterContent(
                                history.novelId,
                                progress.volumeNumber,
                                progress.chapterNumber,
                              );

                      if (currentContext.mounted) {
                        Navigator.push(
                          currentContext,
                          SlideUpPageRoute(
                            page: ReadingPage(
                              chapter: chapter,
                              novelId: history.novelId,
                            ),
                          ),
                        ).then((_) {
                          // 阅读结束后刷新历史列表和小说进度
                          final historyResult = ref.refresh(historyNotifierProvider);
                          // 刷新小说进度
                          final progressResult = ref.refresh(historyProgress(history.novelId));
                          // 使用刷新结果避免编译器警告
                          debugPrint('刷新历史: ${historyResult.hasValue}, 进度: ${progressResult.hasValue}');
                        });
                      }
                    } catch (e) {
                      if (currentContext.mounted) {
                        SnackMessage.show(currentContext, '获取章节失败: $e', isError: true);
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

  void _showOperationMenu(BuildContext context, WidgetRef ref, Novel novel) {
    final currentContext = context;
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
                if (confirmed == true && currentContext.mounted) {
                  try {
                    await ref.read(historyNotifierProvider.notifier).deleteHistory(history.novelId);
                  } catch (e) {
                    if (currentContext.mounted) {
                      SnackMessage.show(currentContext, '删除失败: $e', isError: true);
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
                    page: NovelDetailPage(novel: novel),
                  ),
                ).then((_) {
                  // 从详情页返回后刷新历史列表
                  final historyResult = ref.refresh(historyNotifierProvider);
                  // 刷新小说进度
                  final progressResult = ref.refresh(historyProgress(history.novelId));
                  // 使用刷新结果避免编译器警告
                  debugPrint('刷新历史: ${historyResult.hasValue}, 进度: ${progressResult.hasValue}');
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
