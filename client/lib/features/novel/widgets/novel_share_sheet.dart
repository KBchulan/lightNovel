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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '分享',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close,
                      color: theme.colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(color: theme.colorScheme.outlineVariant),
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
                  color: theme.colorScheme.primary,
                  onTap: () => _shareToSystem(context),
                ),
                _ShareItem(
                  icon: Icons.copy,
                  label: '复制',
                  color: theme.colorScheme.primary,
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
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                  ),
                  child: Text(
                    '取消',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
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
    SnackMessage.show(context, '已复制分享内容');
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
      if (context.mounted) {
        SnackMessage.show(context, '系统分享失败了喵', isError: true);
        Navigator.of(context).pop();
      }
    }
  }

  void _showUnsupportedDialog(BuildContext context, String platform) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('提示', style: theme.textTheme.titleLarge),
        content: Text(
          '对接$platform的功能真的做不出来,可以用复制功能喵',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                Text('确定', style: TextStyle(color: theme.colorScheme.primary)),
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
    final theme = Theme.of(context);
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
                color: color.withAlpha(31),
                shape: BoxShape.circle,
              ),
              child: icon is IconData
                  ? Icon(icon as IconData, color: color, size: 24)
                  : Image.asset(icon as String, width: 24, height: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
