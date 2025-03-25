// ****************************************************************************
//
// @file       reading_page.dart
// @brief      阅读页面
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/chapter.dart';
import '../../../core/providers/reading_provider.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/animations/slide_animation.dart';
import '../../../shared/animations/animation_manager.dart';
import 'package:dio/dio.dart';
import '../../../shared/animations/page_transitions.dart';
import '../widgets/chapter_list_sheet.dart';
import '../widgets/bookmark_sheet.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/settings_sheet.dart';

class ReadingPage extends ConsumerStatefulWidget {
  final Chapter chapter;
  final String novelId;

  const ReadingPage({
    super.key,
    required this.chapter,
    required this.novelId,
  });

  @override
  ConsumerState<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends ConsumerState<ReadingPage>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _controlPanelController;
  late final AnimationController _bottomSheetController;
  late final Animation<double> _controlPanelAnimation;
  bool _isLoading = false;
  bool _isChapterLoading = false;
  bool _isTransitioning = false;
  
  // 图片URL缓存，避免滚动时重新获取
  static final Map<String, List<String>> _imageUrlsCache = {};
  
  // 当前章节的图片URL
  List<String> _chapterImageUrls = [];
  bool _isLoadingImages = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controlPanelController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controlPanelAnimation = CurvedAnimation(
      parent: _controlPanelController,
      curve: Curves.easeInOut,
    );
    _loadReadingProgress();
    
    // 预加载图片URL
    if (widget.chapter.hasImages && widget.chapter.imageCount > 0) {
      _preloadChapterImages();
    }

    _setSystemUIMode(true);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // 确保初始状态下控制面板不显示
    Future.microtask(() {
      ref.read(readingNotifierProvider.notifier).setShowControls(false);
      _controlPanelController.value = 0;
    });

    // 滚动监听
    // _scrollController.addListener(_scrollListener);
  }

  // 控制系统UI的显示和隐藏, true为隐藏, false为显示
  void _setSystemUIMode(bool hideUI) {
    if (hideUI) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    // 移除滚动监听
    // _scrollController.removeListener(_scrollListener);

    _scrollController.dispose();
    _controlPanelController.dispose();
    _bottomSheetController.dispose();

    // 恢复系统UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  // 加载阅读进度，从服务器获取上次阅读位置
  Future<void> _loadReadingProgress() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      try {
        final progress = await apiClient.getReadProgress(widget.novelId);

        if (progress != null &&
            progress.volumeNumber == widget.chapter.volumeNumber &&
            progress.chapterNumber == widget.chapter.chapterNumber) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              _scrollController.jumpTo(progress.position.toDouble());
            }
          });
        }
      } catch (e) {
        if (e is DioException && e.error.toString().contains('响应数据格式错误')) {
          debugPrint('🔍 阅读进度响应为null, 从头开始阅读');
        } else {
          debugPrint('❌ 获取阅读进度错误: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ 加载进度失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 预加载章节图片URL
  Future<void> _preloadChapterImages() async {
    final cacheKey = '${widget.chapter.id}_${widget.chapter.novelId}';
    
    // 如果缓存中已有数据，直接使用
    if (_imageUrlsCache.containsKey(cacheKey)) {
      setState(() {
        _chapterImageUrls = _imageUrlsCache[cacheKey]!;
        _isLoadingImages = false;
      });
      return;
    }
    
    // 否则加载新数据
    setState(() => _isLoadingImages = true);
    try {
      final urls = await ref.read(apiClientProvider).getChapterImageUrls(widget.chapter);
      _imageUrlsCache[cacheKey] = urls;
      
      if (mounted) {
        setState(() {
          _chapterImageUrls = urls;
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      debugPrint('❌ 预加载图片URL错误: $e');
      if (mounted) {
        setState(() => _isLoadingImages = false);
      }
    }
  }

  // 滚动监听 - 防抖
  /*
  void _scrollListener() {
    if (_isScrolling) return;

    final now = DateTime.now();
    if (now.difference(_lastScrollTime).inMilliseconds >= 500) {
      _lastScrollTime = now;
      _isScrolling = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _saveReadingProgress();
          _isScrolling = false;
        }
      });
    }
  }
  */

  // 保存进度，只在退出和章节切换时调用
  Future<void> _saveReadingProgress({int? position}) async {
    if (_isTransitioning) return;

    try {
      if (!_scrollController.hasClients && position == null) return;

      final savePosition =
          position ?? _scrollController.position.pixels.toInt();

      await ref.read(readingNotifierProvider.notifier).updateReadingProgress(
            novelId: widget.novelId,
            volumeNumber: widget.chapter.volumeNumber,
            chapterNumber: widget.chapter.chapterNumber,
            position: savePosition,
          );
    } catch (e) {
      debugPrint('❌ 保存阅读进度错误: $e');
    }
  }

  // 优化章节切换
  Future<void> _handleChapterTransition(bool isNext) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      // 显示加载指示器
      if (mounted) {
        setState(() => _isChapterLoading = true);
      }

      // 保存当前章节的阅读进度
      await _saveReadingProgress(position: 0);

      final apiClient = ref.read(apiClientProvider);
      final chapter = await apiClient.getChapterContent(
        widget.novelId,
        widget.chapter.volumeNumber,
        widget.chapter.chapterNumber + (isNext ? 1 : -1),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          SharedAxisPageRoute(
            page: ReadingPage(
              novelId: widget.novelId,
              chapter: chapter,
            ),
            type: SharedAxisTransitionType.horizontal,
            reverse: !isNext,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(
          context,
          isNext ? '已经是当前卷的最后一话了 \n 休息一下吧喵' : '已经是当前卷的第一话了 \n 前面没有了喵',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChapterLoading = false);
      }
      _isTransitioning = false;
    }
  }

  // 显示自定义提示
  void _showCustomSnackBar(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final snackBarWidget = AnimationManager.buildAnimatedElement(
      type: AnimationType.slideHorizontal,
      duration: AnimationManager.normalDuration,
      curve: AnimationManager.defaultCurve,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(39),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.6,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: snackBarWidget,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  // 显示底部弹窗的通用方法
  void _showBottomSheet(Widget sheet) {
    // 先显示系统UI
    _setSystemUIMode(false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      transitionAnimationController: _bottomSheetController,
      builder: (context) => sheet,
    ).whenComplete(() {
      // 如果控制面板已经隐藏，则恢复隐藏系统UI
      if (!ref.read(readingNotifierProvider).showControls) {
        _setSystemUIMode(true);
      }
    });
  }

  // 优化控制面板显示/隐藏
  void _toggleControls(bool show) {
    if (show) {
      _setSystemUIMode(false);
      _controlPanelController.forward();
    } else {
      _controlPanelController.reverse().whenComplete(() {
        if (mounted) {
          _setSystemUIMode(true);
        }
      });
    }
    ref.read(readingNotifierProvider.notifier).setShowControls(show);
  }

  // 处理文本内容，使其更符合阅读习惯
  String _formatContent(String content) {
    final paragraphs = content.split('\n');
    return paragraphs.map((paragraph) {
      paragraph = paragraph.trim();

      if (paragraph.isEmpty) return '';

      return '　$paragraph';
    }).join('\n\n'); // 段落之间用一个换行符分隔
  }

  @override
  Widget build(BuildContext context) {
    final readingState = ref.watch(readingNotifierProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    Theme.of(context);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _saveReadingProgress();
          if (mounted) {
            final progressResult = ref.refresh(historyProgress(widget.novelId));
            debugPrint('退出阅读页面时刷新进度: ${progressResult.hasValue}');
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: Stack(
          children: [
            // 阅读内容
            Positioned.fill(
              child: _buildReadingContent(readingState, isDark),
            ),

            // 控制面板
            if (readingState.showControls)
              Positioned.fill(
                child: FadeTransition(
                  opacity: _controlPanelAnimation,
                  child: _buildControlPanel(context, isDark),
                ),
              ),

            // 章节加载指示器
            if (_isChapterLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(78),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 阅读内容构建
  Widget _buildReadingContent(ReadingState state, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () => _toggleControls(!state.showControls),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // 判断章节是否有图片
            if (widget.chapter.hasImages && widget.chapter.imageCount > 0)
              _buildChapterImages()
            else
              Text(
                _formatContent(widget.chapter.content),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 构建章节图片组件
  Widget _buildChapterImages() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_isLoadingImages) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 64.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '正在加载插图...',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(204),
                  fontSize: 16,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_chapterImageUrls.isEmpty) {
      return Text(
        _formatContent(widget.chapter.content),
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          letterSpacing: 0.3,
          color: theme.colorScheme.onSurface,
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 如果有文本内容，先显示文本
        if (widget.chapter.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Text(
              _formatContent(widget.chapter.content),
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                letterSpacing: 0.3,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        
        // 显示所有图片 - 美化版本
        ..._chapterImageUrls.map((imageUrl) {
          return Container(
            margin: const EdgeInsets.only(bottom: 28.0),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width,
            ),
            child: Hero(
              tag: 'image_$imageUrl',
              child: Material(
                color: Colors.transparent,
                elevation: isDark ? 4 : 2,
                shadowColor: isDark 
                    ? Colors.black.withAlpha(180) 
                    : Colors.black.withAlpha(80),
                borderRadius: BorderRadius.circular(12.0),
                child: GestureDetector(
                  onTap: () {
                    // 这里可以添加点击图片放大的逻辑
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: MediaQuery.of(context).size.width * 1.2,
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.surfaceContainer.withAlpha(220),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withAlpha(77),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 60,
                                  color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer.withAlpha(150),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.shadow.withAlpha(40),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '图片加载失败',
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          // 图片加载完成，添加淡入效果
                          return AnimatedOpacity(
                            opacity: 1.0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            child: child,
                          );
                        }
                        
                        final percentLoaded = loadingProgress.expectedTotalBytes != null
                            ? (loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!)
                            : null;
                        
                        return Container(
                          height: MediaQuery.of(context).size.width * 1.2,
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surfaceContainerHighest.withAlpha(100)
                                : theme.colorScheme.surfaceContainerLowest.withAlpha(90),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // 背景进度圈
                                      CircularProgressIndicator(
                                        value: percentLoaded,
                                        strokeWidth: 4,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.primary,
                                        ),
                                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                                      ),
                                      // 百分比文字
                                      if (percentLoaded != null)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withAlpha(40),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${(percentLoaded * 100).round()}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '图片加载中',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withAlpha(220),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // 修改底部按钮的点击事件
  Widget _buildControlPanel(BuildContext context, bool isDark) {
    final foregroundColor = isDark ? Colors.white : Colors.black87;
    final headerFooterColor = isDark
        ? Color.lerp(Colors.black, Colors.white, 0.1)
        : Color.lerp(Colors.white, Colors.black, 0.1);

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          // 顶部标题栏
          SlideAnimation(
            direction: SlideDirection.fromTop,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: headerFooterColor,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await _saveReadingProgress();
                      await ref
                          .read(historyNotifierProvider.notifier)
                          .refresh();
                      if (mounted && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: foregroundColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '第${widget.chapter.volumeNumber}卷，第${widget.chapter.chapterNumber}话',
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 中间区域
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleControls(false),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // 底部功能按钮
          SlideAnimation(
            direction: SlideDirection.fromBottom,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: headerFooterColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFunctionButton(
                    Icons.arrow_back_ios,
                    foregroundColor,
                    onTap: () => _handleChapterTransition(false),
                  ),
                  _buildFunctionButton(
                    Icons.bookmark_border,
                    foregroundColor,
                    onTap: () => _showBottomSheet(BookmarkSheet(
                      novelId: widget.novelId,
                      chapter: widget.chapter,
                      currentPosition: _scrollController.hasClients 
                          ? _scrollController.position.pixels.toInt() 
                          : 0,
                      contentLength: _scrollController.hasClients
                          ? _scrollController.position.maxScrollExtent.toInt()
                          : 1000,
                    )),
                  ),
                  _buildFunctionButton(
                    Icons.menu,
                    foregroundColor,
                    onTap: () => _showBottomSheet(ChapterListSheet(
                      novelId: widget.novelId,
                      currentChapter: widget.chapter,
                    )),
                  ),
                  _buildFunctionButton(
                    Icons.chat_bubble_outline,
                    foregroundColor,
                    onTap: () => _showBottomSheet(const CommentSheet()),
                  ),
                  _buildFunctionButton(
                    Icons.settings,
                    foregroundColor,
                    onTap: () => _showBottomSheet(const SettingsSheet()),
                  ),
                  _buildFunctionButton(
                    Icons.arrow_forward_ios,
                    foregroundColor,
                    onTap: () => _handleChapterTransition(true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建功能按钮，包含图标和点击事件
  Widget _buildFunctionButton(
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }
}
