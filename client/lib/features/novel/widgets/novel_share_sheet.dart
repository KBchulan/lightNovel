// ****************************************************************************
//
// @file       novel_share_sheet.dart
// @brief      小说分享组件
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/novel.dart';
import '../../../shared/widgets/snack_message.dart';
import '../../../shared/animations/animation_manager.dart';

class NovelShareSheet extends StatefulWidget {
  final Novel novel;

  const NovelShareSheet({
    super.key,
    required this.novel,
  });

  @override
  State<NovelShareSheet> createState() => _NovelShareSheetState();
}

class _NovelShareSheetState extends State<NovelShareSheet> {
  bool _shouldShowAnimation = true;

  @override
  void initState() {
    super.initState();
    
    // 延迟关闭动画标记，确保动画完整播放一次
    Future.delayed(AnimationManager.mediumDuration, () {
      if (mounted) {
        setState(() {
          _shouldShowAnimation = false;
        });
      }
    });
  }

  String _generateShareUrl() {
    final shareUrl = 'https://lightnovel.app/novel/${widget.novel.id}';
    final shareText =
        '我正在LightNovel阅读《${widget.novel.title}》，推荐给你！$shareUrl';
    return shareText;
  }

  void _showUnsupportedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: const Text('此功能暂未支持，请使用系统分享或复制链接'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _shareToSystem() {
    try {
      // 使用平台通道进行系统分享
      const platform = MethodChannel('com.lightnovel.app/share');
      platform.invokeMethod('shareText', {
        'text': _generateShareUrl(),
        'title': '分享小说',
      });
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        SnackMessage.show(context, '系统分享失败', isError: true);
      }
    }
  }

  void _copyToClipboard() {
    final shareText = _generateShareUrl();
    Clipboard.setData(ClipboardData(text: shareText));
    if (context.mounted) {
      Navigator.pop(context);
      SnackMessage.show(context, '已复制到剪贴板');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 小说信息
            AnimationManager.buildAnimatedElement(
              withAnimation: _shouldShowAnimation,
              type: AnimationType.fade,
              duration: AnimationManager.shortDuration,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.book,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '《${widget.novel.title}》',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.novel.author,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 分隔线
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withAlpha(125),
            ),
            
            const SizedBox(height: 24),
            
            // 分享选项
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    index: 0,
                    icon: 'wechat',
                    label: '微信',
                    iconData: Icons.wechat_outlined,
                    color: const Color(0xFF07C160),
                    onTap: _showUnsupportedDialog,
                  ),
                  _buildShareOption(
                    index: 1,
                    icon: 'moments',
                    label: '朋友圈',
                    iconData: Icons.group_outlined,
                    color: const Color(0xFF07C160),
                    onTap: _showUnsupportedDialog,
                  ),
                  _buildShareOption(
                    index: 2,
                    icon: 'weibo',
                    label: '微博',
                    iconData: Icons.whatshot_outlined,
                    color: const Color(0xFFE6162D),
                    onTap: _showUnsupportedDialog,
                  ),
                  _buildQQShareOption(
                    index: 3,
                    label: 'QQ',
                    color: const Color(0xFF12B7F5),
                    onTap: _showUnsupportedDialog,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    index: 4,
                    icon: 'sms',
                    label: '短信',
                    iconData: Icons.sms_outlined,
                    color: const Color(0xFF5B89F8),
                    onTap: _showUnsupportedDialog,
                  ),
                  _buildShareOption(
                    index: 5,
                    icon: 'copy',
                    label: '复制链接',
                    iconData: Icons.content_copy_outlined,
                    color: isDark ? Colors.white70 : Colors.black54,
                    onTap: _copyToClipboard,
                  ),
                  _buildShareOption(
                    index: 6,
                    icon: 'share',
                    label: '系统分享',
                    iconData: Icons.share_outlined,
                    color: isDark ? Colors.white70 : Colors.black54,
                    onTap: _shareToSystem,
                  ),
                  _buildShareOption(
                    index: 7,
                    icon: 'more',
                    label: '更多',
                    iconData: Icons.more_horiz_outlined,
                    color: isDark ? Colors.white70 : Colors.black54,
                    onTap: _showUnsupportedDialog,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 取消按钮
            AnimationManager.buildAnimatedElement(
              withAnimation: _shouldShowAnimation,
              type: AnimationType.slideUp,
              duration: AnimationManager.normalDuration,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(78),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '取消',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildShareOption({
    required int index,
    required String icon,
    required String label,
    required IconData iconData,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimationManager.buildStaggeredListItem(
      index: index,
      withAnimation: _shouldShowAnimation,
      type: AnimationType.scale,
      duration: AnimationManager.shortDuration,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQQShareOption({
    required int index,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimationManager.buildStaggeredListItem(
      index: index,
      withAnimation: _shouldShowAnimation,
      type: AnimationType.scale,
      duration: AnimationManager.shortDuration,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icons/qq.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
