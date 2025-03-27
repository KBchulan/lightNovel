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
import '../../../core/models/bookmark.dart';
import '../../../core/providers/bookmark_provider.dart';
import '../../../core/providers/api_provider.dart';
import '../../../shared/widgets/novel_card.dart';
import '../../../shared/animations/page_transitions.dart';
import '../../../shared/props/novel_props.dart';
import '../../../shared/animations/animation_manager.dart';
import '../../novel/pages/novel_detail_page.dart';
import '../../reading/pages/reading_page.dart';
import '../widgets/empty_bookshelf.dart';
import '../../../shared/widgets/network_error.dart';

// 定义一个自定义通知类
class SwitchToHomeNotification extends Notification {}

// 视图模式状态提供者 (网格/列表)
final bookshelfViewModeProvider = StateProvider<bool>((ref) => true); // true 表示网格视图

// 书架内容模式状态提供者 (收藏/书签)
final bookshelfContentModeProvider = StateProvider<BookshelfContentMode>((ref) => BookshelfContentMode.favorite);

// 书架内容模式枚举
enum BookshelfContentMode {
  favorite,
  bookmark
}

class BookshelfPage extends ConsumerStatefulWidget {
  const BookshelfPage({super.key});

  @override
  ConsumerState<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends ConsumerState<BookshelfPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _shouldShowAnimation = true;
  bool _isContentReady = false;

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

    // 预先加载所有数据，避免切换时数据不存在
    _loadInitialData();
  }
  
  // 分离数据加载逻辑，提高可维护性
  Future<void> _loadInitialData() async {
    final deviceService = ref.read(deviceServiceProvider);
    await deviceService.getDeviceId();
    
    if (!mounted) return;
    
    // 同时加载收藏和书签数据
    try {
      final favoritesFuture = ref.read(favoriteNotifierProvider.notifier).fetchFavorites();
      final bookmarksFuture = ref.read(bookmarkNotifierProvider.notifier).refresh();
      
      await Future.wait([favoritesFuture, bookmarksFuture]);
      
      if (mounted) {
        setState(() {
          _isContentReady = true;
        });
        
        // 数据加载完成后延迟关闭动画标记
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _shouldShowAnimation = false;
            });
          }
        });
      }
    } catch (e) {
      // 错误处理
      if (mounted) {
        setState(() {
          _isContentReady = true; // 即使出错也标记为ready，以便显示错误状态
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 刷新书架内容
  Future<void> _refreshContent() async {
    setState(() {
      _shouldShowAnimation = true;
    });
    
    // 同时刷新两种数据，而不考虑当前模式
    final favoritesFuture = ref.read(favoriteNotifierProvider.notifier).fetchFavorites();
    final bookmarksFuture = ref.read(bookmarkNotifierProvider.notifier).refresh();
    
    await Future.wait([favoritesFuture, bookmarksFuture]);
    
    if (mounted) {
      setState(() {
        _isContentReady = true;
      });
      
      // 刷新后重新开始动画
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _shouldShowAnimation = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentMode = ref.watch(bookshelfContentModeProvider);
    final isGridView = ref.watch(bookshelfViewModeProvider);
    final theme = Theme.of(context);
    
    // 根据内容模式选择不同的数据源
    final contentAsync = contentMode == BookshelfContentMode.favorite
        ? ref.watch(favoriteNotifierProvider)
        : ref.watch(bookmarkNotifierProvider);
    
    // 判断内容是否准备就绪
    final contentReady = _isContentReady && contentAsync.hasValue;

    // 动画标志
    final shouldAnimate = AnimationManager.shouldAnimateAfterDataLoad(
      hasData: contentAsync.hasValue,
      isLoading: contentAsync.isLoading,
      hasError: contentAsync.hasError,
    ) && _shouldShowAnimation;

    // 使用RepaintBoundary隔离渲染，减少不必要的重绘
    return RepaintBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: Text(contentMode == BookshelfContentMode.favorite ? '收藏' : '书签'),
          actions: [
            // 添加收藏/书签切换菜单
            PopupMenuButton<BookshelfContentMode>(
              icon: Icon(
                contentMode == BookshelfContentMode.favorite
                    ? Icons.book_rounded
                    : Icons.bookmark_rounded,
                color: theme.colorScheme.primary,
              ),
              onSelected: (BookshelfContentMode value) async {
                // 判断是否需要切换模式
                if (value != contentMode) {
                  setState(() {
                    _isContentReady = false;
                  });
                  
                  // 强制预加载当前要切换模式的数据
                  try {
                    if (value == BookshelfContentMode.favorite) {
                      await ref.read(favoriteNotifierProvider.notifier).fetchFavorites();
                    } else {
                      await ref.read(bookmarkNotifierProvider.notifier).refresh();
                    }
                    
                    // 加载完成后再切换模式
                    ref.read(bookshelfContentModeProvider.notifier).state = value;
                    
                    // 确保UI更新
                    if (mounted) {
                      setState(() {
                        _isContentReady = true;
                        _shouldShowAnimation = true;
                      });
                      
                      // 延迟关闭动画标志
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (mounted) {
                          setState(() {
                            _shouldShowAnimation = false;
                          });
                        }
                      });
                    }
                  } catch (e) {
                    // 错误处理：仍然切换模式，但可能显示错误状态
                    ref.read(bookshelfContentModeProvider.notifier).state = value;
                    
                    if (mounted) {
                      setState(() {
                        _isContentReady = true;
                      });
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: BookshelfContentMode.favorite,
                  child: Row(
                    children: [
                      Icon(
                        Icons.book_rounded,
                        color: contentMode == BookshelfContentMode.favorite
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '我的收藏',
                        style: TextStyle(
                          color: contentMode == BookshelfContentMode.favorite
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: contentMode == BookshelfContentMode.favorite
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: BookshelfContentMode.bookmark,
                  child: Row(
                    children: [
                      Icon(
                        Icons.bookmark_rounded,
                        color: contentMode == BookshelfContentMode.bookmark
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '我的书签',
                        style: TextStyle(
                          color: contentMode == BookshelfContentMode.bookmark
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: contentMode == BookshelfContentMode.bookmark
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 视图切换按钮
            if (contentMode == BookshelfContentMode.favorite)
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
        body: AnimatedOpacity(
          opacity: contentReady ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: RefreshIndicator(
            onRefresh: _refreshContent,
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (OverscrollIndicatorNotification notification) {
                // 优化滚动模式，使用更省性能的滚动指示器
                notification.disallowIndicator();
                return true;
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      if (!contentReady)
                        Container(
                          color: theme.scaffoldBackgroundColor,
                        ),
                      contentAsync.when(
                        data: (content) {
                          // 判断当前显示模式并构建相应的视图
                          if (contentMode == BookshelfContentMode.favorite) {
                            return _buildFavoritesView(content as List<Novel>, isGridView, shouldAnimate);
                          } else {
                            return _buildBookmarksView(content as List<Bookmark>, shouldAnimate);
                          }
                        },
                        loading: () => contentReady 
                          ? const SizedBox.shrink() 
                          : const Center(
                              child: CircularProgressIndicator(),
                            ),
                        error: (error, stack) => Stack(
                          children: [
                            NetworkError(
                              message: error.toString(),
                              onRetry: _refreshContent,
                              showPullToRefresh: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建收藏视图
  Widget _buildFavoritesView(List<Novel> favorites, bool isGridView, bool shouldAnimate) {
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

    // 使用缓存键值确保不会不必要地重建
    final cacheKey = '${favorites.length}_${isGridView ? 'grid' : 'list'}_$shouldAnimate';
    
    if (isGridView) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        key: ValueKey(cacheKey),
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
                    type: AnimationType.fade,
                    duration: AnimationManager.normalDuration,
                    child: Hero(
                      tag: 'novel_${novel.id}',
                      flightShuttleBuilder: (
                        BuildContext flightContext,
                        Animation<double> animation,
                        HeroFlightDirection flightDirection,
                        BuildContext fromHeroContext,
                        BuildContext toHeroContext,
                      ) {
                        // 自定义Hero飞行动画，减少性能问题
                        return Material(
                          type: MaterialType.transparency,
                          child: toHeroContext.widget,
                        );
                      },
                      child: Material(
                        type: MaterialType.transparency,
                        child: NovelCard(
                          novel: novel,
                          onTap: () {
                            Navigator.push(
                              context,
                              FadePageRoute(
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
        key: ValueKey(cacheKey),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final novel = favorites[index];
          
          return AnimationManager.buildStaggeredListItem(
            index: index,
            withAnimation: shouldAnimate,
            type: AnimationType.fade,
            duration: AnimationManager.normalDuration,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ListViewNovelCard(novel: novel),
            ),
          );
        },
      );
    }
  }

  // 构建书签视图
  Widget _buildBookmarksView(List<Bookmark> bookmarks, bool shouldAnimate) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(150),
            ),
            const SizedBox(height: 24),
            Text(
              '暂无书签',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '阅读小说时点击底部书签按钮添加',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                SwitchToHomeNotification().dispatch(context);
              },
              icon: const Icon(Icons.explore),
              label: const Text('浏览小说'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 使用缓存键
    final cacheKey = '${bookmarks.length}_bookmark_$shouldAnimate';
    
    return RepaintBoundary(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        key: ValueKey(cacheKey),
        itemCount: bookmarks.length,
        // 使用缓存构建器，避免不必要的重建
        itemBuilder: (context, index) {
          final bookmark = bookmarks[index];
          
          return AnimationManager.buildStaggeredListItem(
            index: index,
            withAnimation: shouldAnimate,
            type: AnimationType.fade,
            duration: AnimationManager.normalDuration,
            child: KeyedSubtree(
              key: ValueKey('bookmark_${bookmark.id}'),
              child: _BookmarkCard(
                bookmark: bookmark,
                onUpdated: () => _refreshContent(),
              ),
            ),
          );
        },
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
            FadePageRoute(
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

// 书签卡片组件
class _BookmarkCard extends ConsumerStatefulWidget {
  final Bookmark bookmark;
  final VoidCallback onUpdated;

  const _BookmarkCard({
    required this.bookmark,
    required this.onUpdated,
  });

  @override
  ConsumerState<_BookmarkCard> createState() => _BookmarkCardState();
}

class _BookmarkCardState extends ConsumerState<_BookmarkCard> {
  bool _isExpanded = false;
  final TextEditingController _noteController = TextEditingController();
  bool _isEditing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.bookmark.note;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // 更新书签备注
  Future<void> _updateBookmark() async {
    setState(() => _isEditing = true);
    try {
      final success = await ref.read(bookmarkNotifierProvider.notifier).updateBookmark(
        widget.bookmark.id,
        _noteController.text.trim(),
      );
      
      if (mounted) {
        if (success) {
          setState(() {
            _isEditing = false;
            _isExpanded = false;
          });
          widget.onUpdated();
          // 显示成功提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('书签更新成功'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          // 显示错误提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('书签更新失败，请稍后重试'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          setState(() => _isEditing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // 删除书签
  Future<void> _deleteBookmark() async {
    setState(() => _isDeleting = true);
    try {
      final success = await ref.read(bookmarkNotifierProvider.notifier).deleteBookmark(
        widget.bookmark.id,
      );
      
      if (mounted) {
        if (success) {
          widget.onUpdated();
          // 显示成功提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('书签已删除'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          // 显示错误提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('书签删除失败，请稍后重试'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        setState(() => _isDeleting = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // 显示删除确认对话框
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除书签'),
        content: const Text('确定要删除这个书签吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBookmark();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 继续阅读
  Future<void> _continueReading() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final chapter = await apiClient.getChapterContent(
        widget.bookmark.novelId,
        widget.bookmark.volumeNumber,
        widget.bookmark.chapterNumber,
      );
      
      if (mounted) {
        Navigator.push(
          context,
          FadePageRoute(
            page: ReadingPage(
              novelId: widget.bookmark.novelId,
              chapter: chapter,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载章节失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookmark = widget.bookmark;
    final date = bookmark.createdAt;
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    return RepaintBoundary(
      child: Card(
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withAlpha(30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: _continueReading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 主信息区域
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 章节信息和创建时间
                    Row(
                      children: [
                        // 书签图标
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(40),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.bookmark_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 章节信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '第${bookmark.volumeNumber}卷 第${bookmark.chapterNumber}话',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withAlpha(170),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 展开/折叠按钮
                        IconButton(
                          icon: Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                        ),
                      ],
                    ),
                    
                    // 书签备注
                    if (bookmark.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withAlpha(80),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            bookmark.note,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // 展开区域 - 编辑备注 (使用更轻量级的动画方式)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  height: _isExpanded ? null : 0,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: _isExpanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 分隔线
                              Container(
                                height: 1,
                                color: theme.colorScheme.outlineVariant.withAlpha(60),
                                margin: const EdgeInsets.only(bottom: 16),
                              ),
                              
                              // 备注输入框
                              TextField(
                                controller: _noteController,
                                decoration: InputDecoration(
                                  hintText: '编辑备注...',
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceContainerLowest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.outlineVariant.withAlpha(80),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                style: theme.textTheme.bodyMedium,
                                minLines: 3,
                                maxLines: 5,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // 操作按钮
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 删除按钮
                                  OutlinedButton.icon(
                                    onPressed: _isDeleting ? null : _showDeleteConfirmDialog,
                                    icon: _isDeleting
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: theme.colorScheme.error,
                                            ),
                                          )
                                        : Icon(
                                            Icons.delete_outline,
                                            color: theme.colorScheme.error,
                                            size: 18,
                                          ),
                                    label: Text(
                                      '删除',
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: theme.colorScheme.error,
                                      side: BorderSide(
                                        color: theme.colorScheme.error.withAlpha(150),
                                      ),
                                    ),
                                  ),
                                  
                                  // 保存按钮
                                  FilledButton.icon(
                                    onPressed: _isEditing ? null : _updateBookmark,
                                    icon: _isEditing
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: theme.colorScheme.onPrimary,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.save_outlined,
                                            size: 18,
                                          ),
                                    label: const Text('保存'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
