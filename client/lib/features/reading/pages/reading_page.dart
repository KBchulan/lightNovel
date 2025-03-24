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
import '../../../shared/widgets/slide_animation.dart';
import 'package:dio/dio.dart';
import '../../../shared/widgets/page_transitions.dart';
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
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _controlPanelController;
  late final Animation<double> _controlPanelAnimation;
  bool _isLoading = false;
  DateTime _lastSaveTime = DateTime.now();
  bool _isScrolling = false;
  DateTime _lastScrollTime = DateTime.now();
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controlPanelController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _controlPanelAnimation = CurvedAnimation(
      parent: _controlPanelController,
      curve: Curves.easeInOut,
    );
    _loadReadingProgress();

    _setSystemUIMode(true);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // 确保初始状态下控制面板不显示
    Future.microtask(() {
      ref.read(readingNotifierProvider.notifier).setShowControls(false);
      _controlPanelController.value = 0;
    });

    // 添加滚动监听，在阅读过程中定期保存进度
    _scrollController.addListener(_scrollListener);
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
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _controlPanelController.dispose();
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

  // 优化滚动监听，使用防抖
  void _scrollListener() {
    if (_isScrolling) return;

    final now = DateTime.now();
    if (now.difference(_lastScrollTime).inSeconds >= 10) {
      _lastScrollTime = now;
      _isScrolling = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _saveReadingProgress();
          _isScrolling = false;
        }
      });
    }
  }

  // 优化保存进度，使用防抖
  Future<void> _saveReadingProgress({int? position}) async {
    if (_isTransitioning) return;

    try {
      if (!_scrollController.hasClients && position == null) return;

      final now = DateTime.now();
      if (now.difference(_lastSaveTime).inSeconds < 2) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _lastSaveTime = now;

      final savePosition =
          position ?? _scrollController.position.pixels.toInt();

      // 使用 Future.wait 并行处理多个异步操作
      await Future.wait([
        ref.read(readingNotifierProvider.notifier).updateReadingProgress(
              novelId: widget.novelId,
              volumeNumber: widget.chapter.volumeNumber,
              chapterNumber: widget.chapter.chapterNumber,
              position: savePosition,
            ),
        ref.read(historyNotifierProvider.notifier).refresh(),
      ]);

      // 并行刷新状态
      ref.invalidate(historyNotifierProvider);
      ref.invalidate(historyProgress(widget.novelId));
    } catch (e) {
      debugPrint('❌ 保存阅读进度错误: $e');
    }
  }

  // 优化章节切换
  Future<void> _handleChapterTransition(bool isNext) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
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
          ChapterTransitionRoute(
            page: ReadingPage(
              novelId: widget.novelId,
              chapter: chapter,
            ),
            isNext: isNext,
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
      _isTransitioning = false;
    }
  }

  // 显示自定义提示
  void _showCustomSnackBar(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 0.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(value * MediaQuery.of(context).size.width, 0),
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
                          : theme.colorScheme.surfaceContainerHighest,
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
              },
            ),
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
      transitionAnimationController: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
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
          ],
        ),
      ),
    );
  }

  // 优化阅读内容构建
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
                    onTap: () => _showBottomSheet(const BookmarkSheet()),
                  ),
                  _buildFunctionButton(
                    Icons.menu,
                    foregroundColor,
                    onTap: () => _showBottomSheet(ChapterListSheet(
                      novelId: widget.novelId,
                      currentVolumeNumber: widget.chapter.volumeNumber,
                      currentChapterNumber: widget.chapter.chapterNumber,
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
