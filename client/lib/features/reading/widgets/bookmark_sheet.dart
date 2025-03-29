// ****************************************************************************
//
// @file       bookmark_sheet.dart
// @brief      书签功能底部弹出组件
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/chapter.dart';
import '../../../core/providers/bookmark_provider.dart';
import '../../../shared/animations/animation_manager.dart';
import '../../../core/providers/volume_provider.dart';

class BookmarkSheet extends ConsumerStatefulWidget {
  final String novelId;
  final Chapter chapter;
  final int currentPosition;
  final int contentLength;

  const BookmarkSheet({
    super.key,
    required this.novelId,
    required this.chapter,
    required this.currentPosition,
    required this.contentLength,
  });

  @override
  ConsumerState<BookmarkSheet> createState() => _BookmarkSheetState();
}

class _BookmarkSheetState extends ConsumerState<BookmarkSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // 获取章节当前显示的第一句话
  String _getFirstVisibleSentence() {
    final content = widget.chapter.content;
    if (content.isEmpty) return '';

    // 使用滚动位置计算当前视图可能在显示的内容
    final totalTextLength = content.length;
    final viewportRatio = widget.currentPosition / widget.contentLength;

    // 预计当前可视区域的开始位置
    final estimatedStartIndex = (viewportRatio * totalTextLength).toInt();
    if (estimatedStartIndex >= totalTextLength) return '';

    // 从估算位置向前查找句子开始
    int sentenceStart = estimatedStartIndex;
    for (int i = estimatedStartIndex; i > 0; i--) {
      // 如果找到句子结束标记，则下一个字符是新句子的开始
      if (i < content.length - 1 &&
          (content[i - 1] == '。' ||
              content[i - 1] == '？' ||
              content[i - 1] == '！' ||
              content[i - 1] == '\n')) {
        sentenceStart = i;
        break;
      }

      // 向前查找最多100个字符
      if (estimatedStartIndex - i > 100) {
        break;
      }
    }

    // 从句子开始位置向后查找句子结束标记
    int sentenceEnd = sentenceStart;
    for (int i = sentenceStart; i < totalTextLength; i++) {
      if (content[i] == '。' ||
          content[i] == '？' ||
          content[i] == '！' ||
          content[i] == '\n') {
        sentenceEnd = i + 1;
        break;
      }

      // 如果找不到句子结束标记，限制句子长度不超过100个字符
      if (i - sentenceStart > 100) {
        sentenceEnd = i;
        break;
      }
    }

    if (sentenceEnd > sentenceStart) {
      return content.substring(sentenceStart, sentenceEnd).trim();
    }

    // 回退措施：如果上面的逻辑没有产生有效结果，则简单截取一段文本
    final fallbackEnd = sentenceStart + 80 < totalTextLength
        ? sentenceStart + 80
        : totalTextLength;
    return '${content.substring(sentenceStart, fallbackEnd).trim()}...';
  }

  @override
  void initState() {
    super.initState();

    // 延迟关闭动画标记，确保动画完整播放一次
    Future.delayed(AnimationManager.shortDuration, () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // 添加书签
  Future<void> _addBookmark() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookmark =
          await ref.read(bookmarkNotifierProvider.notifier).createBookmark(
                novelId: widget.novelId,
                volumeNumber: widget.chapter.volumeNumber,
                chapterNumber: widget.chapter.chapterNumber,
                position: widget.currentPosition,
                note: _noteController.text.trim(),
              );

      if (mounted) {
        if (bookmark != null) {
          Navigator.pop(context);
          _showStatusDialog(context, true);
        } else {
          _showStatusDialog(context, false, message: '添加书签失败，请稍后重试');
          setState(() {
            _errorMessage = '添加书签失败，请稍后重试';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showStatusDialog(context, false, message: '网络错误，请检查连接后重试');
        setState(() {
          _errorMessage = '网络错误，请检查连接后重试';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 显示中央状态弹窗（成功/失败）
  void _showStatusDialog(BuildContext context, bool isSuccess,
      {String? message}) {
    final theme = Theme.of(context);

    // 创建一个透明层的overlay entry
    final OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black.withAlpha(60),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: 260,
                padding: EdgeInsets.symmetric(
                    vertical: isSuccess ? 24 : 20,
                    horizontal: isSuccess ? 0 : 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isSuccess
                    ? _buildSuccessContent(theme)
                    : _buildErrorContent(theme, message),
              ),
            ),
          ),
        ),
      ),
    );

    // 显示弹窗
    overlayState.insert(overlayEntry);

    // 如果是成功状态，自动关闭
    if (isSuccess) {
      Future.delayed(const Duration(seconds: 2), () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      });
    }
  }

  // 构建成功状态内容
  Widget _buildSuccessContent(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withAlpha(230),
                    theme.colorScheme.primary,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(50),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_rounded,
              size: 28,
              color: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '书签添加成功',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // 构建错误状态内容
  Widget _buildErrorContent(ThemeData theme, String? message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.error_outline_rounded,
              size: 28,
              color: theme.colorScheme.error,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '书签添加失败',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.error,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(100),
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              '知道了',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 获取阅读进度百分比
  String _getProgressPercentage() {
    if (widget.contentLength <= 0) return '0%';
    final percentage =
        (widget.currentPosition / widget.contentLength * 100).round();
    return '$percentage%';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final firstSentence = _getFirstVisibleSentence();

    // 键盘高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false, // 禁用自动调整，我们将手动处理键盘
      body: PopScope(
        canPop: !keyboardVisible,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            FocusScope.of(context).unfocus();
          }
        },
        child: Container(
          margin: EdgeInsets.only(bottom: keyboardHeight),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.52, // 固定高度
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部拖动条
                  Container(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withAlpha(25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 标题栏 - 更紧凑的版本
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6.0, vertical: 2.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '添加书签',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          iconSize: 22,
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),

                  // 内容区域
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 6.0,
                        bottom: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 当前章节信息
                          Hero(
                            tag: 'bookmark_card',
                            flightShuttleBuilder: (_, __, ___, ____, _____) =>
                                const SizedBox(),
                            child: Card(
                              elevation: 0,
                              color: theme.colorScheme.primaryContainer
                                  .withAlpha(30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color:
                                      theme.colorScheme.primary.withAlpha(25),
                                  width: 1,
                                ),
                              ),
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.book_outlined,
                                          color: theme.colorScheme.primary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '当前位置',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _getProgressPercentage(),
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final params = ChapterTitleParams(
                                          novelId: widget.novelId,
                                          volumeNumber: widget.chapter.volumeNumber,
                                          chapterNumber: widget.chapter.chapterNumber,
                                        );
                                        
                                        final titleAsync = ref.watch(chapterTitleProvider(params));
                                        
                                        return Text(
                                          titleAsync.when(
                                            data: (title) => '第${widget.chapter.volumeNumber}卷 $title',
                                            loading: () => '第${widget.chapter.volumeNumber}卷 第${widget.chapter.chapterNumber}话',
                                            error: (_, __) => '第${widget.chapter.volumeNumber}卷 第${widget.chapter.chapterNumber}话',
                                          ),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        );
                                      },
                                    ),
                                    if (firstSentence.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.9, end: 1.0),
                                        duration:
                                            const Duration(milliseconds: 400),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: child,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme.surfaceContainer
                                                .withAlpha(70),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            firstSentence,
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontSize: 14,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 笔记输入框
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '备注',
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Theme(
                                  // 覆盖输入框选中时的颜色
                                  data: Theme.of(context).copyWith(
                                    inputDecorationTheme:
                                        InputDecorationTheme(
                                      fillColor:
                                          theme.colorScheme.surfaceContainer,
                                      filled: true,
                                    ),
                                  ),
                                  child: Focus(
                                    onFocusChange: (hasFocus) {
                                      // 当获取焦点或失去焦点时，不需要额外处理
                                    },
                                    child: TextField(
                                      controller: _noteController,
                                      decoration: InputDecoration(
                                        hintText: '记录一下此时的想法和感受吧...',
                                        hintStyle: TextStyle(
                                          color: theme
                                              .colorScheme.onSurfaceVariant
                                              .withAlpha(123),
                                          fontSize: 14,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: theme
                                                .colorScheme.outlineVariant
                                                .withAlpha(80),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        // 保持填充颜色不变
                                        fillColor: theme
                                            .colorScheme.surfaceContainer,
                                        filled: true,
                                      ),
                                      style: theme.textTheme.bodyMedium,
                                      minLines: 4,
                                      maxLines: 5,
                                    ),
                                  ),
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 按钮
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.95, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _addBookmark,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor:
                                      theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      )
                                    : const Text(
                                        '添加书签',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
