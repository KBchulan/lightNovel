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

class NovelShareSheet extends StatelessWidget {
  final Novel novel;

  const NovelShareSheet({
    super.key,
    required this.novel,
  });

  String get _shareUrl => 'lightnovel://novel/${novel.id}';

  String get _shareText => '''${novel.title}
作者：${novel.author}
打开lightnovel查看:$_shareUrl''';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  '分享',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(),
          // 分享选项
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ShareItem(
                  icon: 'assets/icons/wechat.png',
                  label: '微信',
                  color: const Color(0xFF07C160),
                  onTap: () => _showUnsupportedDialog(context, '微信'),
                ),
                _ShareItem(
                  icon: 'assets/icons/qq.png',
                  label: 'QQ',
                  color: const Color(0xFF12B7F5),
                  onTap: () => _showUnsupportedDialog(context, 'QQ'),
                ),
                _ShareItem(
                  icon: Icons.share,
                  label: '分享',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => _shareToSystem(context),
                ),
                _ShareItem(
                  icon: Icons.copy,
                  label: '复制',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => _copyShareLink(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 取消按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('取消'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyShareLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '已复制分享内容',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        width: 200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        duration: const Duration(seconds: 2),
        animation: null,
      ),
    );
    Navigator.of(context).pop();
  }

  void _shareToSystem(BuildContext context) async {
    const platform = MethodChannel('com.lightnovel.app/share');
    try {
      await platform.invokeMethod('shareText', {
        'text': _shareText,
        'title': novel.title,
      });
      if (context.mounted) Navigator.of(context).pop();
    } catch (error) {
      if (context.mounted) _showErrorDialog(context, '系统分享失败');
    }
  }

  void _showUnsupportedDialog(BuildContext context, String platform) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: Text('暂不支持直接分享到$platform, 请使用复制功能后手动分享'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _ShareItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 72,
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
              child: icon is IconData
                  ? Icon(icon as IconData, color: color, size: 24)
                  : Image.asset(icon as String, width: 24, height: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
} 