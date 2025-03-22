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
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/slide_animation.dart';

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

class _ReadingPageState extends ConsumerState<ReadingPage> {
  late ScrollController _scrollController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initReadingState();
    
    // 设置全屏和竖屏
    _setSystemUIMode(true);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  // 控制系统UI的显示和隐藏
  void _setSystemUIMode(bool hideUI) {
    if (hideUI) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _initReadingState() async {
    setState(() => _isLoading = true);
    try {
      // 设置当前章节
      ref.read(readingNotifierProvider.notifier)
        ..setCurrentChapter(widget.chapter)
        ..setReadingMode(ReadingMode.scroll)  // 设置为滚动模式
        ..setShowControls(false);  // 默认隐藏控制栏
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readingState = ref.watch(readingNotifierProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark || 
                   (themeMode == ThemeMode.system && 
                    MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // 根据控制面板的显示状态切换系统UI
    _setSystemUIMode(!readingState.showControls);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // 阅读内容 - 使用固定位置
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildReadingContent(readingState, isDark),
          ),
          
          // 控制面板 - 使用Positioned.fill确保完全覆盖
          if (readingState.showControls)
            Positioned.fill(
              child: _buildControlPanel(context, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildReadingContent(ReadingState state, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        ref.read(readingNotifierProvider.notifier).toggleShowControls();
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              widget.chapter.content,
              style: TextStyle(
                fontSize: 16,
                height: 1.8,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, bool isDark) {
    final foregroundColor = isDark ? Colors.white : Colors.black87;
    final headerFooterColor = isDark 
        ? Color.lerp(Colors.black, Colors.white, 0.1)
        : Color.lerp(Colors.white, Colors.black, 0.1);

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          // 顶部标题栏 - 添加滑动动画
          SlideAnimation(
            direction: SlideDirection.fromTop,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
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
                    onTap: () {
                      Navigator.of(context).pop();
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
          
          // 中间区域 - 透明背景，点击时隐藏控制面板
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(readingNotifierProvider.notifier).setShowControls(false);
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          
          // 底部功能按钮 - 添加滑动动画
          SlideAnimation(
            direction: SlideDirection.fromBottom,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: headerFooterColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFunctionButton(Icons.skip_previous, foregroundColor),
                  _buildFunctionButton(Icons.home, foregroundColor),
                  _buildFunctionButton(Icons.bookmark_border, foregroundColor),
                  _buildFunctionButton(Icons.settings, foregroundColor),
                  _buildFunctionButton(Icons.skip_next, foregroundColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionButton(IconData icon, Color color) {
    return Icon(
      icon,
      color: color,
      size: 28,
    );
  }
} 