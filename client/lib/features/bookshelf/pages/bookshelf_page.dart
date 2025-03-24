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
import '../../../shared/animations/page_transitions.dart';
import '../../../shared/props/novel_props.dart';
import '../../../shared/animations/animation_manager.dart';
import '../../novel/pages/novel_detail_page.dart';
import '../widgets/empty_bookshelf.dart';
import '../../../shared/widgets/network_error.dart';

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
  bool _shouldShowAnimation = true;

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
    
    // 数据加载完成后延迟关闭动画标记
    if (favoritesAsync.hasValue && _shouldShowAnimation) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _shouldShowAnimation = false;
          });
        }
      });
    }

    final shouldAnimate = AnimationManager.shouldAnimateAfterDataLoad(
      hasData: favoritesAsync.hasValue,
      isLoading: favoritesAsync.isLoading,
      hasError: favoritesAsync.hasError,
    ) && _shouldShowAnimation;

    return Scaffold(
      appBar: AppBar(
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
      body: RefreshIndicator(
        onRefresh: () {
          setState(() {
            _shouldShowAnimation = true;
          });
          return ref.read(favoriteNotifierProvider.notifier).fetchFavorites();
        },
        child: favoritesAsync.when(
          data: (favorites) {
            if (favorites.isEmpty) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: EmptyBookshelf(
                      onExplore: () {
                        SwitchToHomeNotification().dispatch(context);
                      },
                    ),
                  ),
                ],
              );
            }

            if (isGridView) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
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
                          
                          return AnimationManager.buildStaggeredListItem(
                            index: index,
                            withAnimation: shouldAnimate,
                            type: AnimationType.scale,
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
                    ),
                  ),
                ],
              );
            } else {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final novel = favorites[index];
                  
                  return AnimationManager.buildStaggeredListItem(
                    index: index,
                    withAnimation: shouldAnimate,
                    type: AnimationType.slideUp,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ListViewNovelCard(novel: novel),
                    ),
                  );
                },
              );
            }
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Stack(
            children: [
              NetworkError(
                message: error.toString(),
                onRetry: () => ref.read(favoriteNotifierProvider.notifier).fetchFavorites(),
                showPullToRefresh: true,
              ),
            ],
          ),
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
