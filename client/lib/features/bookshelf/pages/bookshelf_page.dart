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
import 'dart:async';
import '../../../core/providers/novel_provider.dart';
import '../../../core/services/device_service.dart';
import '../../../core/models/novel.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/providers/bookmark_provider.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/volume_provider.dart';
import '../../../shared/widgets/novel_card.dart';
import '../../../shared/animations/page_transitions.dart';
import '../../../shared/props/novel_props.dart';
import '../../../shared/animations/animation_manager.dart';
import '../../../shared/widgets/snack_message.dart';
import '../../novel/pages/novel_detail_page.dart';
import '../../reading/pages/reading_page.dart';
import '../../../shared/widgets/network_error.dart';
import '../widgets/empty_bookshelf.dart';

// 自定义通知类，用于切换到首页
class SwitchToHomeNotification extends Notification {}

// 视图模式状态提供者 (网格/列表)
final bookshelfViewModeProvider =
    StateProvider<bool>((ref) => true); // true 表示网格视图

// 书架内容模式状态提供者 (收藏/书签)
final bookshelfContentModeProvider =
    StateProvider<BookshelfContentMode>((ref) => BookshelfContentMode.favorite);

// 书架内容模式枚举
enum BookshelfContentMode { favorite, bookmark }

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

  // 动画延迟时间常量
  static const _animationDelayMs = 800;
  static const _modeChangeAnimationDelayMs = 600;

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

    // 预先加载所有数据
    _loadInitialData();
  }

  // 延迟关闭动画标记
  void _delayCloseAnimation(int delayMs) {
    if (!mounted) return;

    // 移除对动画状态的更新，避免闪烁
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        setState(() => _shouldShowAnimation = false);
      }
    });
  }

  // 分离数据加载逻辑
  Future<void> _loadInitialData() async {
    final deviceService = ref.read(deviceServiceProvider);
    await deviceService.getDeviceId();

    if (!mounted) return;

    try {
      // 同时加载收藏和书签数据
      await _refreshAllData();
      
      // 设置内容已准备好标志
      if (mounted) {
        setState(() {
          _isContentReady = true;
        });
        
        // 延迟关闭动画标记
        _delayCloseAnimation(_animationDelayMs);
      }
    } catch (e) {
      // 处理错误
      if (mounted) {
        setState(() {
          _isContentReady = true;
        });
      }
    }
  }
  
  // 刷新所有数据
  Future<void> _refreshAllData() async {
    await Future.wait([
      ref.read(favoriteNotifierProvider.notifier).fetchFavorites(),
      ref.read(bookmarkNotifierProvider.notifier).refresh(),
    ]);
  }
  
  // 处理刷新内容操作
  Future<void> _refreshContent() async {
    // 设置动画状态为true，触发动画效果
    setState(() {
      _shouldShowAnimation = true;
    });
    
    await _refreshAllData();
    
    // 延迟关闭动画标记
    _delayCloseAnimation(_animationDelayMs);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 切换内容模式（收藏/书签）
  Future<void> _switchContentMode(BookshelfContentMode newMode) async {
    final currentMode = ref.read(bookshelfContentModeProvider);

    // 判断是否需要切换模式
    if (newMode == currentMode) return;

    setState(() => _isContentReady = false);

    try {
      // 预加载要切换的模式数据
      if (newMode == BookshelfContentMode.favorite) {
        await ref.read(favoriteNotifierProvider.notifier).fetchFavorites();
      } else {
        await ref.read(bookmarkNotifierProvider.notifier).refresh();
      }

      // 切换模式
      ref.read(bookshelfContentModeProvider.notifier).state = newMode;

      if (mounted) {
        setState(() {
          _isContentReady = true;
          _shouldShowAnimation = true;
        });

        _delayCloseAnimation(_modeChangeAnimationDelayMs);
      }
    } catch (e) {
      // 即使出错也切换模式
      ref.read(bookshelfContentModeProvider.notifier).state = newMode;

      if (mounted) {
        setState(() => _isContentReady = true);
      }
    }
  }

  // 处理视图模式变化
  void _handleViewModeChange() {
    // 设置动画状态为true，触发动画效果
    setState(() {
      _shouldShowAnimation = true;
    });
    
    final isGridView = ref.read(bookshelfViewModeProvider);
    ref.read(bookshelfViewModeProvider.notifier).state = !isGridView;
    
    // 根据当前是否为网格视图决定动画方向
    if (isGridView) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    
    // 切换模式后延迟关闭动画
    _delayCloseAnimation(_modeChangeAnimationDelayMs);
  }

  @override
  Widget build(BuildContext context) {
    final contentMode = ref.watch(bookshelfContentModeProvider);
    final isGridView = ref.watch(bookshelfViewModeProvider);
    final theme = Theme.of(context);

    // 根据内容模式选择数据源
    final contentAsync = contentMode == BookshelfContentMode.favorite
        ? ref.watch(favoriteNotifierProvider)
        : ref.watch(bookmarkNotifierProvider);

    final contentReady = _isContentReady && contentAsync.hasValue;
    final shouldAnimate = AnimationManager.shouldAnimateAfterDataLoad(
          hasData: contentAsync.hasValue,
          isLoading: contentAsync.isLoading,
          hasError: contentAsync.hasError,
        ) &&
        _shouldShowAnimation;

    return Scaffold(
      appBar: _buildAppBar(contentMode, isGridView, theme),
      body: AnimatedOpacity(
        opacity: contentReady ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: RefreshIndicator(
          onRefresh: _refreshContent,
          child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (notification) {
              notification.disallowIndicator();
              return true;
            },
            child: _buildContent(contentAsync, contentMode, isGridView,
                contentReady, shouldAnimate, theme),
          ),
        ),
      ),
    );
  }

  // 构建AppBar
  PreferredSizeWidget _buildAppBar(
      BookshelfContentMode contentMode, bool isGridView, ThemeData theme) {
    return AppBar(
      title: Text(contentMode == BookshelfContentMode.favorite ? '收藏' : '书签'),
      actions: [
        // 内容模式切换菜单
        PopupMenuButton<BookshelfContentMode>(
          icon: Icon(
            contentMode == BookshelfContentMode.favorite
                ? Icons.book_rounded
                : Icons.bookmark_rounded,
            color: theme.colorScheme.primary,
          ),
          onSelected: _switchContentMode,
          itemBuilder: (context) => [
            _buildModeMenuItem(
              mode: BookshelfContentMode.favorite,
              currentMode: contentMode,
              icon: Icons.book_rounded,
              label: '我的收藏',
              theme: theme,
            ),
            _buildModeMenuItem(
              mode: BookshelfContentMode.bookmark,
              currentMode: contentMode,
              icon: Icons.bookmark_rounded,
              label: '我的书签',
              theme: theme,
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
              onPressed: _handleViewModeChange,
            ),
          ),
      ],
    );
  }

  // 构建模式菜单项
  PopupMenuItem<BookshelfContentMode> _buildModeMenuItem({
    required BookshelfContentMode mode,
    required BookshelfContentMode currentMode,
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    final isSelected = mode == currentMode;

    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // 构建主内容
  Widget _buildContent(
    AsyncValue contentAsync,
    BookshelfContentMode contentMode,
    bool isGridView,
    bool contentReady,
    bool shouldAnimate,
    ThemeData theme,
  ) {
    return Stack(
      children: [
        if (!contentReady) Container(color: theme.scaffoldBackgroundColor),
        contentAsync.when(
          data: (content) {
            if (contentMode == BookshelfContentMode.favorite) {
              final sortedFavorites = List<Novel>.from(content as List<Novel>)
                ..sort((a, b) => a.id.compareTo(b.id));
              return _buildFavoritesView(
                  sortedFavorites, isGridView, shouldAnimate);
            } else {
              final sortedBookmarks = List<Bookmark>.from(content as List<Bookmark>)
                ..sort((a, b) => a.id.compareTo(b.id));
              return _buildBookmarksView(sortedBookmarks, shouldAnimate);
            }
          },
          loading: () => contentReady
              ? const SizedBox.shrink()
              : const Center(child: CircularProgressIndicator()),
          error: (error, stack) => NetworkError(
            message: error.toString(),
            onRetry: _refreshContent,
            showPullToRefresh: true,
          ),
        ),
      ],
    );
  }

  // 构建收藏视图
  Widget _buildFavoritesView(
      List<Novel> favorites, bool isGridView, bool shouldAnimate) {
    if (favorites.isEmpty) {
      return _buildEmptyFavoritesView();
    }

    // 缓存键
    final cacheKey =
        '${favorites.length}_${isGridView ? 'grid' : 'list'}_$shouldAnimate';

    if (isGridView) {
      return _buildGridView(favorites, cacheKey, shouldAnimate);
    } else {
      return _buildListView(favorites, cacheKey, shouldAnimate);
    }
  }

  // 构建空收藏视图
  Widget _buildEmptyFavoritesView() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: EmptyBookshelf(
            onExplore: () => SwitchToHomeNotification().dispatch(context),
          ),
        ),
      ],
    );
  }

  // 构建网格视图
  Widget _buildGridView(
      List<Novel> novels, String cacheKey, bool shouldAnimate) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      key: ValueKey(cacheKey),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final novel = novels[index];

                return AnimationManager.buildStaggeredListItem(
                  index: index,
                  withAnimation: shouldAnimate,
                  type: AnimationType.combined,
                  duration: AnimationManager.normalDuration,
                  child: Hero(
                    tag: 'novel_${novel.id}',
                    flightShuttleBuilder:
                        (_, animation, direction, fromContext, toContext) {
                      return Material(
                        type: MaterialType.transparency,
                        child: toContext.widget,
                      );
                    },
                    child: Material(
                      type: MaterialType.transparency,
                      child: NovelCard(
                        novel: novel,
                        onTap: () => _navigateToNovelDetail(novel),
                      ),
                    ),
                  ),
                );
              },
              childCount: novels.length,
            ),
          ),
        ),
      ],
    );
  }

  // 构建列表视图
  Widget _buildListView(
      List<Novel> novels, String cacheKey, bool shouldAnimate) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      key: ValueKey(cacheKey),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: novels.length,
      itemBuilder: (context, index) {
        final novel = novels[index];

        return AnimationManager.buildStaggeredListItem(
          index: index,
          withAnimation: shouldAnimate,
          type: AnimationType.combined,
          duration: AnimationManager.normalDuration,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ListViewNovelCard(novel: novel),
          ),
        );
      },
    );
  }

  // 导航到小说详情页
  void _navigateToNovelDetail(Novel novel) {
    Navigator.push(
      context,
      FadePageRoute(
        page: NovelDetailPage(novel: novel),
      ),
    );
  }

  // 构建书签视图
  Widget _buildBookmarksView(List<Bookmark> bookmarks, bool shouldAnimate) {
    if (bookmarks.isEmpty) {
      return _buildEmptyBookmarksView();
    }

    // 缓存键
    final cacheKey = '${bookmarks.length}_bookmark_$shouldAnimate';

    return RepaintBoundary(
      child: _BookmarkListView(
        bookmarks: bookmarks,
        shouldAnimate: shouldAnimate,
        cacheKey: cacheKey,
        onUpdated: _refreshContent,
      ),
    );
  }

  // 构建空书签视图
  Widget _buildEmptyBookmarksView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    // 创建图标组件
    final iconWidget = Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(20),
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 背景装饰
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(40),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha(20),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),

            // 图标设计
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha(40),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: primaryColor.withAlpha(40),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 36,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );

    // 创建标题文字组件
    final titleWidget = Text(
      '暂无书签',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );

    // 创建副标题文字组件
    final subtitleWidget = Text(
      '阅读小说时点击底部书签按钮添加',
      style: TextStyle(
        fontSize: 15,
        color: colorScheme.outline,
        height: 1.4,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.center,
    );

    // 创建按钮组件
    final buttonWidget = FilledButton.icon(
      onPressed: () => SwitchToHomeNotification().dispatch(context),
      icon: const Icon(Icons.explore_outlined),
      label: const Text('浏览小说'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
      ),
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 使用动画管理器创建所有动画元素
                      AnimationManager.buildEmptyStateAnimation(
                        context: context,
                        icon: iconWidget,
                        title: titleWidget,
                        subtitle: subtitleWidget,
                        button: buttonWidget,
                        iconAnimationType: AnimationType.scale,
                        textAnimationType: AnimationType.slideUp,
                        buttonAnimationType: AnimationType.scale,
                        iconDuration: AnimationManager.mediumDuration,
                        textDuration: AnimationManager.normalDuration,
                        buttonDuration: AnimationManager.normalDuration,
                        iconCurve: AnimationManager.bouncyCurve,
                      ),

                      const SizedBox(height: 36),

                      // 底部装饰元素
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDecorativeElement(5, primaryColor.withAlpha(100)),
                          const SizedBox(width: 10),
                          _buildDecorativeElement(6, primaryColor.withAlpha(120)),
                          const SizedBox(width: 10),
                          _buildDecorativeElement(5, primaryColor.withAlpha(100)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 装饰元素
  Widget _buildDecorativeElement(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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

// 书签列表视图组件
class _BookmarkListView extends ConsumerStatefulWidget {
  final List<Bookmark> bookmarks;
  final bool shouldAnimate;
  final String cacheKey;
  final VoidCallback onUpdated;

  const _BookmarkListView({
    required this.bookmarks,
    required this.shouldAnimate,
    required this.cacheKey,
    required this.onUpdated,
  });

  @override
  ConsumerState<_BookmarkListView> createState() => _BookmarkListViewState();
}

class _BookmarkListViewState extends ConsumerState<_BookmarkListView> {
  bool _isLoading = true;
  Map<String, Novel> _novelsMap = {};
  
  @override
  void initState() {
    super.initState();
    // 批量加载所有书签相关的小说信息
    _batchLoadNovelInfo();
  }
  
  // 批量加载小说信息
  Future<void> _batchLoadNovelInfo() async {
    if (widget.bookmarks.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final Map<String, Novel> novelsMap = {};
      
      // 使用Set去重小说ID
      final Set<String> uniqueNovelIds = widget.bookmarks
          .map((bookmark) => bookmark.novelId)
          .toSet();
      
      // 并行加载所有小说信息
      final futures = uniqueNovelIds.map((novelId) async {
        try {
          final novel = await apiClient.getNovelDetail(novelId);
          return MapEntry(novelId, novel);
        } catch (e) {
          debugPrint('加载小说信息失败: $e');
          return null;
        }
      });
      
      // 等待所有请求完成
      final results = await Future.wait(futures);
      
      // 过滤掉失败的请求并构建映射
      for (final result in results) {
        if (result != null) {
          novelsMap[result.key] = result.value;
        }
      }
      
      if (mounted) {
        setState(() {
          _novelsMap = novelsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('批量加载小说信息失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 如果正在加载，显示加载指示器
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      key: ValueKey(widget.cacheKey),
      itemCount: widget.bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = widget.bookmarks[index];
        // 获取预加载的小说信息
        final preloadedNovel = _novelsMap[bookmark.novelId];
        
        // 只有初次加载时显示动画，后续操作不使用动画
        final useAnimation = widget.shouldAnimate && index < 15;

        return AnimationManager.buildStaggeredListItem(
          index: index,
          withAnimation: useAnimation,
          type: AnimationType.combined, 
          duration: AnimationManager.normalDuration,
          child: KeyedSubtree(
            key: ValueKey('bookmark_${bookmark.id}'),
            child: _BookmarkCard(
              bookmark: bookmark,
              onUpdated: widget.onUpdated,
              preloadedNovel: preloadedNovel,
            ),
          ),
        );
      },
    );
  }
}

// 书签卡片组件
class _BookmarkCard extends ConsumerStatefulWidget {
  final Bookmark bookmark;
  final VoidCallback onUpdated;
  final Novel? preloadedNovel; // 添加预加载的小说信息参数

  const _BookmarkCard({
    required this.bookmark,
    required this.onUpdated,
    this.preloadedNovel, // 可选的预加载小说信息
  });

  @override
  ConsumerState<_BookmarkCard> createState() => _BookmarkCardState();
}

class _BookmarkCardState extends ConsumerState<_BookmarkCard> {
  bool _isExpanded = false;
  final TextEditingController _noteController = TextEditingController();
  bool _isEditing = false;
  Novel? _novel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.bookmark.note;
    
    // 使用预加载的小说信息或加载小说信息
    if (widget.preloadedNovel != null) {
      _novel = widget.preloadedNovel;
      _isLoading = false;
    } else {
      _loadNovelInfo();
    }
  }

  // 加载小说信息
  Future<void> _loadNovelInfo() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final novel = await apiClient.getNovelDetail(widget.bookmark.novelId);
      if (mounted) {
        setState(() {
          _novel = novel;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('加载小说信息失败: ${e.toString()}', isError: true);
      }
    }
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
      final success =
          await ref.read(bookmarkNotifierProvider.notifier).updateBookmark(
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
          _showSnackBar('书签更新成功', isError: false);
        } else {
          _showSnackBar('书签更新失败，请稍后重试', isError: true);
          setState(() => _isEditing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEditing = false);
        _showSnackBar('更新失败: ${e.toString()}', isError: true);
      }
    }
  }

  // 删除书签
  Future<void> _deleteBookmark() async {
    try {
      final success =
          await ref.read(bookmarkNotifierProvider.notifier).deleteBookmark(
                widget.bookmark.id,
              );

      if (mounted) {
        if (success) {
          widget.onUpdated();
          _showSnackBar('书签已删除', isError: false);
        } else {
          _showSnackBar('书签删除失败，请稍后重试', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('删除失败: ${e.toString()}', isError: true);
      }
    }
  }

  // 显示Snackbar消息
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
    final currentContext = context;
    try {
      // 先预加载卷列表数据
      final volumesAsync = ref.read(volumeNotifierProvider);
      if (!volumesAsync.hasValue || volumesAsync.asData?.value.isEmpty == true) {
        // 如果卷数据未加载，先加载卷数据
        await ref.read(volumeNotifierProvider.notifier).fetchVolumes(widget.bookmark.novelId);
      }
      
      // 获取章节内容
      final chapter = await ref
          .read(apiClientProvider)
          .getChapterContent(
              widget.bookmark.novelId, widget.bookmark.volumeNumber, widget.bookmark.chapterNumber);

      if (currentContext.mounted) {
        Navigator.push(
          currentContext,
          FadePageRoute(
            page: ReadingPage(
              chapter: chapter,
              novelId: widget.bookmark.novelId,
            ),
          ),
        ).then((_) {
          // 刷新书架
          ref.invalidate(favoriteNotifierProvider);
          ref.invalidate(bookmarkNotifierProvider);
        });
      }
    } catch (e) {
      if (currentContext.mounted) {
        SnackMessage.show(currentContext, '获取章节失败: $e',
            isError: true);
      }
    }
  }

  // 跳转到小说详情页
  void _navigateToNovelDetail() {
    if (_novel != null) {
      Navigator.push(
        context,
        FadePageRoute(
          page: NovelDetailPage(novel: _novel!),
        ),
      );
    } else {
      _showSnackBar('无法获取小说信息', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookmark = widget.bookmark;
    final date = bookmark.createdAt;
    final formattedDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return RepaintBoundary(
      child: Dismissible(
        key: Key('bookmark_dismissible_${bookmark.id}'),
        background: _buildDismissBackground(theme, isLeft: true),
        secondaryBackground: _buildDismissBackground(theme, isLeft: false),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            // 右滑到左
            _showDeleteConfirmDialog();
            return false;
          } else {
            // 左滑到右
            setState(() {
              _isExpanded = true;
            });
            return false;
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主卡片
            Card(
              elevation: 2,
              shadowColor: theme.colorScheme.shadow.withAlpha(30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.only(bottom: _isExpanded ? 0 : 16),
              child: Stack(
                children: [
                  Positioned.fill(
                    left: 85,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _continueReading,
                        splashColor: theme.colorScheme.primary.withAlpha(25),
                        highlightColor: theme.colorScheme.primary.withAlpha(12),
                      ),
                    ),
                  ),

                  // 内容区域
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 封面图片
                      SizedBox(
                        width: 85,
                        child: Center(
                          child: SizedBox(
                            height: 148,
                            width: 90,
                            child: GestureDetector(
                              onTap: _navigateToNovelDetail,
                              child: Container(
                                color: theme.colorScheme.surfaceContainerLow,
                                child: _isLoading || _novel == null
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : NovelProps.buildCoverImage(
                                        NovelProps.getCoverUrl(_novel!),
                                        height: double.infinity,
                                        width: 85,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 右侧内容区
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 小说标题
                              if (_novel != null)
                                Text(
                                  _novel!.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                              if (_isLoading && _novel == null)
                                Container(
                                  height: 20,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color:
                                        theme.colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),

                              const SizedBox(height: 6),

                              // 章节信息
                              Text(
                                '第${bookmark.volumeNumber}卷 第${bookmark.chapterNumber}话',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),

                              const SizedBox(height: 4),

                              // 创建时间
                              Text(
                                formattedDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(170),
                                ),
                              ),

                              // 书签备注
                              if (bookmark.note.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme
                                                .surfaceContainerLow,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: theme
                                                  .colorScheme.outlineVariant
                                                  .withAlpha(80),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            bookmark.note,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                          color: theme.colorScheme.primary,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isExpanded = true;
                                          });
                                        },
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
                ],
              ),
            ),

            // 编辑区域 - 从上方弹出，使用SlideTransition
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isExpanded ? null : 0,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: _isExpanded
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withAlpha(20),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: _isExpanded
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 备注输入框
                          TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              hintText: '编辑备注...',
                              filled: true,
                              fillColor:
                                  theme.colorScheme.surfaceContainerLowest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outlineVariant
                                      .withAlpha(80),
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
                              // 取消按钮
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isExpanded = false;
                                  });
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(180),
                                  size: 18,
                                ),
                                label: Text(
                                  '取消',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(180),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.onSurface,
                                  side: BorderSide(
                                    color: theme.colorScheme.outlineVariant,
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
          ],
        ),
      ),
    );
  }

  // 构建滑动背景
  Widget _buildDismissBackground(ThemeData theme, {required bool isLeft}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isLeft
            ? theme.colorScheme.primary.withAlpha(50)
            : theme.colorScheme.error.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLeft) ...[
            Icon(
              Icons.edit_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '编辑',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            Text(
              '删除',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
            ),
          ],
        ],
      ),
    );
  }
}
