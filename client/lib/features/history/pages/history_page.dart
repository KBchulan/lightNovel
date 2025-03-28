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
import '../../../core/providers/volume_provider.dart';
import '../../../shared/animations/page_transitions.dart';
import '../../../shared/widgets/snack_message.dart';
import '../../../shared/props/novel_props.dart';
import '../../novel/pages/novel_detail_page.dart';
import '../../reading/pages/reading_page.dart';
import '../widgets/empty_history.dart';
import '../../../shared/widgets/network_error.dart';
import '../../../shared/animations/animation_manager.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyNotifierProvider);
    final theme = Theme.of(context);
    final sortType = ref.watch(historySortTypeProvider);
    final isAscending = ref.watch(historySortOrderProvider);
    // 监听加载完成状态
    final isLoadingComplete = ref.watch(historyLoadingCompleteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('历史'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearHistoryDialog(context, ref);
              } else if (value == 'sort_time') {
                ref.read(historyNotifierProvider.notifier).sortByTime();
              } else if (value == 'sort_name') {
                ref.read(historyNotifierProvider.notifier).sortByName();
              } else if (value == 'sort_asc') {
                if (!isAscending) {
                  ref.read(historyNotifierProvider.notifier).toggleSortOrder();
                }
              } else if (value == 'sort_desc') {
                if (isAscending) {
                  ref.read(historyNotifierProvider.notifier).toggleSortOrder();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sort_time',
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: sortType == 'time'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '按时间排序',
                      style: TextStyle(
                        color: sortType == 'time'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort_name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      size: 20,
                      color: sortType == 'name'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '按名称排序',
                      style: TextStyle(
                        color: sortType == 'name'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort_asc',
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 20,
                      color: isAscending
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '升序',
                      style: TextStyle(
                        color: isAscending
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort_desc',
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      size: 20,
                      color: !isAscending
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '降序',
                      style: TextStyle(
                        color: !isAscending
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 8),
                    Text('清空历史'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(historyNotifierProvider.notifier).refresh(),
        child: Stack(
          children: [
            // 加载状态指示器 - 使用AnimatedOpacity控制显示/隐藏
            AnimatedOpacity(
              opacity: historyAsync.isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: theme.scaffoldBackgroundColor,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '加载中...',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 内容区域 - 使用AnimatedOpacity控制显示/隐藏
            AnimatedOpacity(
              opacity: (historyAsync.hasValue && isLoadingComplete) || historyAsync.hasError ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: historyAsync.when(
                data: (histories) {
                  // 添加调试信息，帮助排查问题
                  debugPrint('📚 历史记录数量: ${histories.length}, 加载完成: $isLoadingComplete');
                  
                  if (histories.isEmpty) {
                    return AnimationManager.buildAnimatedElement(
                      type: AnimationType.slideUp,
                      duration: AnimationManager.mediumDuration,
                      child: const CustomScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.all(16),
                            sliver: EmptyHistory(),
                          ),
                        ],
                      ),
                    );
                  }

                  // 按日期对历史记录进行分组
                  final Map<String, List<ReadHistory>> groupedHistories = {};
                  for (var history in histories) {
                    final dateKey = _formatDateForGrouping(history.lastRead);
                    if (!groupedHistories.containsKey(dateKey)) {
                      groupedHistories[dateKey] = [];
                    }
                    groupedHistories[dateKey]!.add(history);
                  }

                  // 定义日期优先级顺序，用于排序
                  final dateOrder = {
                    'today': 0,
                    'yesterday': 1,
                    'thisWeek': 2,
                    'thisMonth': 3,
                    'earlier': 4
                  };

                  // 处理日期轴的排序
                  final sortedDates = groupedHistories.keys.toList();

                  // 默认情况下，按时间排序，降序
                  sortedDates.sort((a, b) {
                    final orderA = dateOrder[a] ?? 999;
                    final orderB = dateOrder[b] ?? 999;

                    if (sortType == 'time' && isAscending) {
                      return orderB.compareTo(orderA);
                    } else {
                      return orderA.compareTo(orderB);
                    }
                  });

                  return AnimationManager.buildAnimatedElement(
                    type: AnimationType.slideUp,
                    duration: AnimationManager.mediumDuration,
                    startOffset: const Offset(0, 50),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: sortedDates.length,
                      itemBuilder: (context, index) {
                        final dateKey = sortedDates[index];
                        final dateHistories = groupedHistories[dateKey]!;

                        // 处理组内记录的排序
                        if (sortType == 'time') {
                          dateHistories.sort((a, b) => b.lastRead.compareTo(a.lastRead));
                        } else {
                          final titleMap = ref.read(historyTitleMapProvider);
                          if (titleMap.isNotEmpty) {
                            dateHistories.sort((a, b) {
                              final titleA = titleMap[a.novelId] ?? '';
                              final titleB = titleMap[b.novelId] ?? '';
                              return isAscending
                                  ? titleA.compareTo(titleB)
                                  : titleB.compareTo(titleA);
                            });
                          } else {
                            dateHistories.sort((a, b) => b.lastRead.compareTo(a.lastRead));
                          }
                        }

                        return AnimationManager.buildStaggeredListItem(
                          index: index,
                          type: AnimationType.slideUp,
                          duration: AnimationManager.mediumDuration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _formatDateGroupHeader(dateKey),
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Divider(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...dateHistories.asMap().entries.map((entry) {
                                int itemIndex = entry.key;
                                ReadHistory itemHistory = entry.value;
                                return AnimationManager.buildStaggeredListItem(
                                  index: itemIndex,
                                  type: AnimationType.slideUp,
                                  duration: AnimationManager.shortDuration,
                                  child: _HistoryItem(
                                    key: ValueKey('history_${itemHistory.id}'),
                                    history: itemHistory,
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => AnimationManager.buildAnimatedElement(
                  type: AnimationType.slideUp,
                  duration: AnimationManager.mediumDuration,
                  child: NetworkError(
                    message: error.toString(),
                    onRetry: () => ref.refresh(historyNotifierProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 格式化日期用于分组
  String _formatDateForGrouping(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.year == now.year &&
        dateOnly.month == now.month &&
        dateOnly.day == now.day) {
      return 'today';
    } else if (dateOnly.year == yesterday.year &&
        dateOnly.month == yesterday.month &&
        dateOnly.day == yesterday.day) {
      return 'yesterday';
    } else if (now.difference(dateOnly).inDays < 7) {
      return 'thisWeek';
    } else if (dateOnly.year == now.year && dateOnly.month == now.month) {
      return 'thisMonth';
    } else {
      return 'earlier'; // 改为"以前"分组，替代之前的年月分组
    }
  }

  // 格式化日期组标题
  String _formatDateGroupHeader(String dateKey) {
    switch (dateKey) {
      case 'today':
        return '今天';
      case 'yesterday':
        return '昨天';
      case 'thisWeek':
        return '本周';
      case 'thisMonth':
        return '本月';
      case 'earlier':
        return '以前';
      default:
        return dateKey;
    }
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
    final theme = Theme.of(context);

    final isLoading = novelAsync.isLoading || progressAsync.isLoading;
    final hasError = novelAsync.hasError || progressAsync.hasError;

    // 获取数据
    final novel = novelAsync.valueOrNull;
    final progress = progressAsync.valueOrNull;

    // 使用从底部滑入的加载指示器，替代之前的淡入效果
    if (isLoading) {
      return AnimationManager.buildAnimatedElement(
        type: AnimationType.slideUp,
        duration: AnimationManager.shortDuration,
        startOffset: const Offset(0, 30),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 152,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withAlpha(26),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                ),
                const SizedBox(height: 12),
                Text(
                  '加载中...',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (hasError || novel == null || progress == null) {
      return const SizedBox.shrink();
    }

    // 计算一个模拟的阅读进度百分比
    final estimatedProgress =
        (progress.volumeNumber * 0.7 + progress.chapterNumber * 0.3) / 100;
    final clampedProgress = estimatedProgress.clamp(0.05, 0.95);

    return Dismissible(
      key: Key('history_${history.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(123),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.delete_outline,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '删除',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (direction) async {
        final currentContext = context;
        try {
          await ref
              .read(historyNotifierProvider.notifier)
              .deleteHistory(history.novelId);
        } catch (e) {
          if (currentContext.mounted) {
            SnackMessage.show(currentContext, '删除失败: $e', isError: true);
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 1,
        surfaceTintColor: Colors.white,
        child: InkWell(
          onTap: () {
            final currentContext = context;
            Navigator.push(
              currentContext,
              NovelDetailPageRoute(page: NovelDetailPage(novel: novel)),
            ).then((_) {
              if (currentContext.mounted) {
                final historyResult = ref.refresh(historyNotifierProvider);
                final progressResult =
                    ref.refresh(historyProgress(history.novelId));
                debugPrint(
                    '刷新历史: ${historyResult.hasValue}, 进度: ${progressResult.hasValue}');
              }
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
                    Stack(
                      children: [
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
                        // 添加一个半透明的阴影覆盖层
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 40,
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
                        ),
                        // 阅读进度指示器
                        Positioned(
                          bottom: 4,
                          left: 4,
                          right: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '阅读进度',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withAlpha(204),
                                ),
                              ),
                              const SizedBox(height: 2),
                              LinearProgressIndicator(
                                value: clampedProgress,
                                backgroundColor: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(2),
                                minHeight: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: theme.colorScheme.primary.withAlpha(191),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                novel.author,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      theme.colorScheme.primary.withAlpha(191),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(31),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '第${progress.volumeNumber}卷 第${progress.chapterNumber}话',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatLastReadTime(history.lastRead),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          if (novel.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: novel.tags.take(2).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        theme.colorScheme.primary.withAlpha(21),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.primary
                                          .withAlpha(230),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
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
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    final currentContext = context;
                    try {
                      // 先预加载卷列表数据
                      final volumesAsync = ref.read(volumeNotifierProvider);
                      if (!volumesAsync.hasValue || volumesAsync.asData?.value.isEmpty == true) {
                        // 如果卷数据未加载，先加载卷数据
                        await ref.read(volumeNotifierProvider.notifier).fetchVolumes(history.novelId);
                      }
                      
                      // 获取章节内容
                      final chapter =
                          await ref.read(apiClientProvider).getChapterContent(
                                history.novelId,
                                progress.volumeNumber,
                                progress.chapterNumber,
                              );

                      if (currentContext.mounted) {
                        Navigator.push(
                          currentContext,
                          FadePageRoute(
                            page: ReadingPage(
                              chapter: chapter,
                              novelId: history.novelId,
                            ),
                          ),
                        ).then((_) {
                          final historyResult =
                              ref.refresh(historyNotifierProvider);
                          final progressResult =
                              ref.refresh(historyProgress(history.novelId));
                          debugPrint(
                              '刷新历史: ${historyResult.hasValue}, 进度: ${progressResult.hasValue}');
                        });
                      }
                    } catch (e) {
                      if (currentContext.mounted) {
                        SnackMessage.show(currentContext, '获取章节失败: $e',
                            isError: true);
                      }
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, size: 18),
                      SizedBox(width: 8),
                      Text('继续阅读'),
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

  // 格式化上次阅读时间，提供更友好的显示
  String _formatLastReadTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return NovelProps.formatDateTime(time);
    }
  }

  void _showOperationMenu(BuildContext context, WidgetRef ref, Novel novel) {
    final currentContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部小条
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withAlpha(102),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 小说基本信息
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 封面缩略图
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 50,
                        height: 75,
                        child: NovelProps.buildCoverImage(
                          NovelProps.getCoverUrl(novel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 小说信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            novel.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            novel.author,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // 操作列表
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('继续阅读'),
                onTap: () async {
                  Navigator.pop(context);
                  final progressAsync =
                      ref.read(historyProgress(history.novelId));
                  final progress = progressAsync.valueOrNull;

                  if (progress == null) {
                    if (currentContext.mounted) {
                      SnackMessage.show(currentContext, '无法获取阅读进度',
                          isError: true);
                    }
                    return;
                  }

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
                        FadePageRoute(
                          page: ReadingPage(
                            chapter: chapter,
                            novelId: history.novelId,
                          ),
                        ),
                      ).then((_) {
                        // 阅读结束后刷新历史列表和小说进度
                        final historyResult =
                            ref.refresh(historyNotifierProvider);
                        final progressResult =
                            ref.refresh(historyProgress(history.novelId));
                        debugPrint(
                            '刷新历史: ${historyResult.hasValue}, 进度: ${progressResult.hasValue}');
                      });
                    }
                  } catch (e) {
                    if (currentContext.mounted) {
                      SnackMessage.show(currentContext, '获取章节失败: $e',
                          isError: true);
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
                    NovelDetailPageRoute(page: NovelDetailPage(novel: novel)),
                  ).then((_) {
                    final historyResult = ref.refresh(historyNotifierProvider);
                    final progressResult =
                        ref.refresh(historyProgress(history.novelId));
                    debugPrint(
                        '刷新历史: ${historyResult.hasValue}, 进度: ${progressResult.hasValue}');
                  });
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除此记录', style: TextStyle(color: Colors.red)),
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
                      await ref
                          .read(historyNotifierProvider.notifier)
                          .deleteHistory(history.novelId);
                    } catch (e) {
                      if (currentContext.mounted) {
                        SnackMessage.show(currentContext, '删除失败: $e',
                            isError: true);
                      }
                    }
                  }
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
