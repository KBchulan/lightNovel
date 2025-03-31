// ****************************************************************************
//
// @file       comment_sheet.dart
// @brief      评论功能底部弹出组件
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/models/comment_response.dart';
import '../../../shared/animations/animation_manager.dart';
import '../../../config/app_config.dart';
import 'dart:async';

/// 用户头像组件，处理头像加载和错误情况
class UserAvatarWidget extends StatefulWidget {
  final String avatarUrl;
  final double size;

  const UserAvatarWidget({
    super.key,
    required this.avatarUrl,
    this.size = 36,
  });

  @override
  State<UserAvatarWidget> createState() => _UserAvatarWidgetState();
}

class _UserAvatarWidgetState extends State<UserAvatarWidget> {
  String? _cachedAvatarUrl;
  bool _isDefaultAvatar = false;
  bool _useIconFallback = false;

  @override
  void initState() {
    super.initState();
    _updateCachedUrl();
  }

  @override
  void didUpdateWidget(UserAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _isDefaultAvatar = false;
      _useIconFallback = false;
      _updateCachedUrl();
    }
  }

  void _updateCachedUrl() {
    if (widget.avatarUrl.isEmpty ||
        widget.avatarUrl == "/static/avatars/default.png" ||
        widget.avatarUrl == "/static/avatars/default.jpg") {
      _cachedAvatarUrl = '${AppConfig.staticUrl}/static/avatars/default.png';
      _isDefaultAvatar = true;
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _cachedAvatarUrl = widget.avatarUrl.startsWith('http')
        ? '${widget.avatarUrl}${widget.avatarUrl.contains('?') ? '&' : '?'}t=$timestamp'
        : '${AppConfig.staticUrl}${widget.avatarUrl}${widget.avatarUrl.contains('?') ? '&' : '?'}t=$timestamp';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget defaultAvatar = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withAlpha(26),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: widget.size * 0.5,
          color: theme.colorScheme.primary,
        ),
      ),
    );

    if (_useIconFallback) {
      return defaultAvatar;
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withAlpha(26),
      ),
      child: ClipOval(
        child: Image.network(
          _isDefaultAvatar
              ? '${AppConfig.staticUrl}/static/avatars/default.png'
              : _cachedAvatarUrl!,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
          cacheWidth: null,
          cacheHeight: null,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('头像加载失败: $error，路径: $_cachedAvatarUrl');
            if (!_isDefaultAvatar) {
              _isDefaultAvatar = true;
              Future.microtask(() {
                if (mounted) setState(() {});
              });
              return Image.network(
                '${AppConfig.staticUrl}/static/avatars/default.png',
                fit: BoxFit.cover,
                width: widget.size,
                height: widget.size,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('默认头像也加载失败: $error');
                  _useIconFallback = true;
                  Future.microtask(() {
                    if (mounted) setState(() {});
                  });
                  return defaultAvatar;
                },
              );
            }
            // 如果是默认头像加载失败，则使用Icon
            _useIconFallback = true;
            Future.microtask(() {
              if (mounted) setState(() {});
            });
            return defaultAvatar;
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            );
          },
        ),
      ),
    );
  }
}

class CommentSheet extends ConsumerStatefulWidget {
  final String novelId;
  final int volumeNumber;
  final int chapterNumber;

  const CommentSheet({
    super.key,
    required this.novelId,
    required this.volumeNumber,
    required this.chapterNumber,
  });

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<CommentResponse> _comments = [];
  bool _isLoading = false;
  bool _isSendingComment = false;
  bool _hasMoreComments = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  
  String? _currentUserId;
  bool _isRefreshing = false;
  Timer? _refreshDebouncer;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadUserProfile();
    
    // 添加滚动监听，实现加载更多
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _refreshDebouncer?.cancel();
    super.dispose();
  }
  
  // 滚动监听器，实现加载更多
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreComments) {
        _loadMoreComments();
      }
    }
  }
  
  // 加载用户资料
  Future<void> _loadUserProfile() async {
    try {
      final user = await ref.read(apiClientProvider).getUserProfile();
      if (mounted) {
        setState(() {
          _currentUserId = user.id;
        });
      }
    } catch (e) {
      debugPrint('❌ 加载用户资料失败: $e');
    }
  }

  // 加载评论列表
  Future<void> _loadComments() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (_currentPage == 1) {
        _comments = [];
      }
    });

    try {
      final comments = await ref.read(apiClientProvider).getChapterComments(
        novelId: widget.novelId,
        volumeNumber: widget.volumeNumber,
        chapterNumber: widget.chapterNumber,
        page: _currentPage,
        size: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (_currentPage == 1) {
            _comments = comments;
          } else {
            _comments.addAll(comments);
          }
          _hasMoreComments = comments.length >= _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ 加载评论失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('加载评论失败，请稍后重试'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 1),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
  
  // 加载更多评论
  Future<void> _loadMoreComments() async {
    if (_isLoading || !_hasMoreComments) return;
    
    setState(() {
      _currentPage++;
    });
    
    await _loadComments();
  }
  
  // 刷新评论列表
  Future<void> _refreshComments() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    
    // 使用延迟器，避免频繁刷新
    _refreshDebouncer?.cancel();
    _refreshDebouncer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _currentPage = 1;
      });
      
      await _loadComments();
      _isRefreshing = false;
    });
  }

  // 删除评论
  Future<void> _deleteComment(String commentId) async {
    try {
      await ref.read(apiClientProvider).deleteComment(commentId);
      
      if (mounted) {
        // 从列表中移除此评论
        setState(() {
          _comments.removeWhere((comment) => comment.id == commentId);
        });
      }
    } catch (e) {
      debugPrint('❌ 删除评论失败: $e');
      if (mounted) {
        // 仅在删除失败时显示提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('删除评论失败，请稍后重试'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 1),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
  
  // 发送评论
  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
    setState(() {
      _isSendingComment = true;
    });

    try {
      final newComment = await ref.read(apiClientProvider).createComment(
        novelId: widget.novelId,
        volumeNumber: widget.volumeNumber,
        chapterNumber: widget.chapterNumber,
        content: content,
      );

      if (mounted) {
        _commentController.clear();
        
        // 隐藏键盘
        FocusScope.of(context).unfocus();
        
        // 获取用户信息，构建完整的评论显示对象
        final user = await ref.read(apiClientProvider).getUserProfile();
        
        // 添加到评论列表顶部，实现即时反馈
        setState(() {
          _comments.insert(0, CommentResponse(
            id: newComment.id,
            userId: user.id,
            userName: user.name,
            userAvatar: user.avatar,
            novelId: widget.novelId,
            volumeNumber: widget.volumeNumber,
            chapterNumber: widget.chapterNumber,
            content: content,
            createdAt: DateTime.now(),
          ));
          _isSendingComment = false;
        });
      }
    } catch (e) {
      debugPrint('❌ 发送评论失败: $e');
      if (mounted) {
        setState(() {
          _isSendingComment = false;
        });
        
        // 仅在发送失败时显示提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('评论发表失败，请稍后重试'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 1),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          margin: EdgeInsets.only(bottom: keyboardHeight),
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
              
              // 标题栏
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '评论区',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _isLoading ? null : _refreshComments,
                      tooltip: '刷新评论',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // 评论列表
              Expanded(
                child: _buildCommentList(isKeyboardVisible),
              ),
              
              // 评论输入框
              _buildCommentInput(),
            ],
          ),
        );
      },
    );
  }
  
  // 构建评论列表
  Widget _buildCommentList(bool isKeyboardVisible) {
    if (_isLoading && _comments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(70),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无评论，快来发表第一条评论吧！',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
      );
    }
    
    return Stack(
      children: [
        // 评论列表
        RefreshIndicator(
          onRefresh: _refreshComments,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: isKeyboardVisible ? 16 : 8,
            ),
            itemCount: _comments.length + (_hasMoreComments ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _comments.length) {
                // 加载更多的指示器
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              }
              
              final comment = _comments[index];
              final isMyComment = comment.userId == _currentUserId;
              
              return AnimationManager.buildStaggeredListItem(
                index: index,
                withAnimation: index < 10, // 只对前10条评论添加动画
                type: AnimationType.fade,
                duration: AnimationManager.shortDuration,
                child: _buildCommentItem(comment, isMyComment),
              );
            },
          ),
        ),
        
        // 底部加载指示器
        if (_isLoading && _comments.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Theme.of(context).colorScheme.surface.withAlpha(200),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  // 构建单个评论项
  Widget _buildCommentItem(CommentResponse comment, bool isMyComment) {
    final theme = Theme.of(context);
    
    return Dismissible(
      // 只有自己的评论才能滑动删除
      key: Key('comment_${comment.id}'),
      direction: isMyComment ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: theme.colorScheme.error,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        // 只有自己的评论才能删除
        if (!isMyComment) return false;
        
        // 直接返回true确认删除，无需额外确认
        return true;
      },
      onDismissed: (direction) {
        _deleteComment(comment.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户头像 - 使用新的UserAvatarWidget组件
            UserAvatarWidget(
              avatarUrl: comment.userAvatar,
              size: 36,
            ),
            
            const SizedBox(width: 12),
            
            // 评论内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户名和删除按钮
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.userName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isMyComment
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isMyComment)
                        GestureDetector(
                          onTap: () => _deleteComment(comment.id),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: theme.colorScheme.error.withAlpha(180),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 评论内容
                  Text(
                    comment.content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 评论时间
                  Text(
                    _formatTime(comment.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withAlpha(130),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建评论输入框
  Widget _buildCommentInput() {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 评论输入框
          Expanded(
            child: TextField(
              controller: _commentController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: '说点什么吧...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(130),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainer,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _sendComment(),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // 发送按钮
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            child: IconButton(
              onPressed: _isSendingComment ? null : _sendComment,
              icon: _isSendingComment
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    color: theme.colorScheme.primary,
                  ),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 格式化时间显示
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
} 