// ****************************************************************************
//
// @file       bookshelf_page.dart
// @brief      书架页面
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/novel_provider.dart';
import '../../../core/services/device_service.dart';
import '../../../core/models/novel.dart';
import '../../../shared/widgets/novel_card.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/props/novel_props.dart';
import '../../novel/pages/novel_detail_page.dart';
import '../widgets/empty_bookshelf.dart';

// 定义一个自定义通知类
class SwitchToHomeNotification extends Notification {}

// 视图模式状态提供者
final bookshelfViewModeProvider =
    StateProvider<bool>((ref) => true); // true 表示网格视图

class BookshelfPage extends ConsumerStatefulWidget {
  const BookshelfPage({super.key});

  @override
  ConsumerState<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends ConsumerState<BookshelfPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // 根据当前视图模式设置动画控制器的初始状态
    if (!ref.read(bookshelfViewModeProvider)) {
      _controller.forward();
    }

    // 确保先初始化设备ID，再加载收藏列表
    Future.microtask(() async {
      final deviceService = ref.read(deviceServiceProvider);
      await deviceService.getDeviceId();
      if (mounted) {
        ref.read(favoriteNotifierProvider.notifier).fetchFavorites();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoriteNotifierProvider);
    final isGridView = ref.watch(bookshelfViewModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(favoriteNotifierProvider.notifier).fetchFavorites(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: theme.colorScheme.surface,
              title: const Text('书架'),
              actions: [
                // 视图切换按钮
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: IconButton(
                    key: ValueKey(isGridView),
                    icon: AnimatedIcon(
                      icon: AnimatedIcons.view_list,
                      progress: _controller,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      final notifier =
                          ref.read(bookshelfViewModeProvider.notifier);
                      notifier.state = !notifier.state;
                      if (notifier.state) {
                        _controller.reverse();
                      } else {
                        _controller.forward();
                      }
                    },
                  ),
                ),
              ],
            ),

            // 内容区域
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: favoritesAsync.when(
                data: (favorites) {
                  if (favorites.isEmpty) {
                    return EmptyBookshelf(
                      onExplore: () {
                        SwitchToHomeNotification().dispatch(context);
                      },
                    );
                  }

                  if (isGridView) {
                    return SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final novel = favorites[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 300 + index * 50),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: Hero(
                              tag: 'novel_${novel.id}',
                              child: Material(
                                type: MaterialType.transparency,
                                child: NovelCard(
                                  novel: novel,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      NovelDetailPageRoute(
                                        page: NovelDetailPage(novel: novel),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: favorites.length,
                      ),
                    );
                  } else {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final novel = favorites[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 300 + index * 50),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ListViewNovelCard(novel: novel),
                            ),
                          );
                        },
                        childCount: favorites.length,
                      ),
                    );
                  }
                },
                loading: () => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withAlpha(26),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '加载失败了喵',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (error.toString() != 'null')
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  error.toString(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.error.withAlpha(204),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () {
                                ref
                                    .read(favoriteNotifierProvider.notifier)
                                    .fetchFavorites();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('重试'),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: theme.colorScheme.onError,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 添加一个可拉动区域以触发RefreshIndicator
                      ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 列表视图的小说卡片
class _ListViewNovelCard extends StatelessWidget {
  final Novel novel;

  const _ListViewNovelCard({
    required this.novel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withAlpha(26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            NovelDetailPageRoute(
              page: NovelDetailPage(novel: novel),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 封面
              Hero(
                tag: 'novel_${novel.id}_list',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 120,
                    child: NovelProps.buildCoverImage(
                      NovelProps.getCoverUrl(novel),
                      width: 80,
                      height: 120,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      novel.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      novel.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (novel.tags.isNotEmpty) // 只在有标签时显示
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: novel.tags.take(2).map<Widget>((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(38),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
