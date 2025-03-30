// ****************************************************************************
//
// @file       settings_page.dart
// @brief      设置页面
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/theme/app_theme.dart';
import '../../../config/app_config.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/models/models.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // 控制展开折叠状态
  bool _isThemeExpanded = false;
  bool _isAboutExpanded = false;
  bool _isAppExpanded = false;
  bool _isUserExpanded = false;
  
  // 用户信息
  User? _user;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    // 加载用户资料
    _loadUserProfile();
  }
  
  // 加载用户资料
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final user = await apiClient.getUserProfile();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载用户资料失败: $e')),
        );
      }
    }
  }
  
  // 选择并上传头像
  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    // 打开图片选择器
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // 限制图片宽度
      maxHeight: 800, // 限制图片高度
      imageQuality: 85, // 压缩质量
    );
    
    if (image != null && mounted) {
      try {
        // 显示加载对话框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在上传头像...')
                ],
              ),
            );
          },
        );
        
        final apiClient = ref.read(apiClientProvider);
        final updatedUser = await apiClient.uploadAvatarAndUpdateProfile(
          File(image.path),
        );
        
        if (mounted) {
          // 关闭对话框
          Navigator.of(context).pop();
          
          setState(() {
            _user = updatedUser;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('头像更新成功')),
          );
        }
      } catch (e) {
        if (mounted) {
          // 关闭对话框
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('头像更新失败: $e')),
          );
        }
      }
    }
  }

  // 打开URL链接
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    // 在异步操作前先检查context是否挂载
    if (!mounted) return;

    try {
      if (!await url_launcher.launchUrl(uri)) {
        if (mounted) {
          // 再次检查mounted状态
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无法打开链接: $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // 异常处理中也要检查mounted状态
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开链接失败: $e')),
        );
      }
    }
  }

  // 发送邮件
  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=${AppConfig.appName}用户反馈');
    // 在异步操作前先检查context是否挂载
    if (!mounted) return;

    try {
      if (!await url_launcher.launchUrl(uri)) {
        if (mounted) {
          // 再次检查mounted状态
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开邮件客户端')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // 异常处理中也要检查mounted状态
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送邮件失败: $e')),
        );
      }
    }
  }

  // 主题切换处理
  Future<void> _handleThemeChange(ThemeMode? value) async {
    if (value != null) {
      final currentThemeMode = ref.read(themeNotifierProvider);
      if (value == ThemeMode.system) {
        ref.read(themeNotifierProvider.notifier).setThemeMode(value);
        return;
      }
      if (value == currentThemeMode) {
        return;
      }
      ref.read(themeNotifierProvider.notifier).setThemeMode(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          
          // 用户信息
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shadowColor: theme.colorScheme.shadow.withAlpha(26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildUserSection(theme),
          ),
          
          // 主题设置
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shadowColor: theme.colorScheme.shadow.withAlpha(26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildThemeSection(theme, currentThemeMode),
          ),

          // 应用信息
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shadowColor: theme.colorScheme.shadow.withAlpha(26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildAppInfoSection(theme),
          ),

          // 关于作者
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shadowColor: theme.colorScheme.shadow.withAlpha(26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildAboutSection(theme),
          ),

          // 版权声明
          const SizedBox(height: 16),
          Center(
            child: Text(
              '© ${DateTime.now().year} ${AppConfig.authorName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(128),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${AppConfig.appName} ${AppConfig.appVersion}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(128),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  // 用户信息区域
  Widget _buildUserSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          icon: Icons.account_circle,
          title: '个人资料',
          isExpanded: _isUserExpanded,
          onTap: () {
            setState(() {
              _isUserExpanded = !_isUserExpanded;
            });
          },
        ),
        if (_isUserExpanded) ...[
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_user != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 头像
                  GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(
                            _user!.avatar.startsWith('http') 
                            ? _user!.avatar 
                            : '${AppConfig.staticUrl}${_user!.avatar}',
                          ),
                          backgroundColor: theme.colorScheme.primary.withAlpha(26),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 用户名
                  Text(
                    _user!.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 加入时间
                  Text(
                    '加入时间: ${_formatDate(_user!.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // 最后活跃时间
                  Text(
                    '最后活跃: ${_formatDate(_user!.lastActiveAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 修改用户名按钮
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: 实现修改用户名功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('修改用户名功能开发中')),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('修改用户名'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('获取用户资料失败')),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
  
  // 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 主题设置区域
  Widget _buildThemeSection(ThemeData theme, ThemeMode currentThemeMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          icon: Icons.palette,
          title: '主题设置',
          isExpanded: _isThemeExpanded,
          onTap: () {
            setState(() {
              _isThemeExpanded = !_isThemeExpanded;
            });
          },
        ),
        if (_isThemeExpanded) ...[
          _ThemeModeOption(
            title: '跟随系统',
            icon: Icons.brightness_auto,
            value: ThemeMode.system,
            groupValue: currentThemeMode,
            onChanged: _handleThemeChange,
          ),
          _ThemeModeOption(
            title: '浅色主题',
            icon: Icons.light_mode,
            value: ThemeMode.light,
            groupValue: currentThemeMode,
            onChanged: _handleThemeChange,
          ),
          _ThemeModeOption(
            title: '深色主题',
            icon: Icons.dark_mode,
            value: ThemeMode.dark,
            groupValue: currentThemeMode,
            onChanged: _handleThemeChange,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // 应用信息区域
  Widget _buildAppInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          icon: Icons.info_outline,
          title: '应用信息',
          isExpanded: _isAppExpanded,
          onTap: () {
            setState(() {
              _isAppExpanded = !_isAppExpanded;
            });
          },
        ),
        if (_isAppExpanded) ...[
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Column(
              children: [
                _buildInfoItem(
                  theme,
                  icon: Icons.book,
                  title: '应用名称',
                  value: AppConfig.appName,
                ),
                _buildInfoItem(
                  theme,
                  icon: Icons.tag,
                  title: '版本号',
                  value: AppConfig.appVersion,
                ),
                _buildActionItem(
                  theme,
                  icon: Icons.update,
                  title: '检查更新',
                  onTap: () {
                    // 显示检查更新的提示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('当前已是最新版本', style: TextStyle(fontSize: 15)),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: theme.colorScheme.primary,
                        elevation: 6,
                        margin: const EdgeInsets.all(12),
                        action: SnackBarAction(
                          label: '确定',
                          textColor: Colors.black,
                          onPressed: () {},
                        ),
                      ),
                    );
                  },
                ),
                _buildActionItem(
                  theme,
                  icon: Icons.data_usage,
                  title: '清除缓存',
                  onTap: () {
                    // 显示清除缓存的对话框
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('确认清除缓存?'),
                        content: const Text('这将清除所有本地缓存数据，但不会影响您的收藏。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('缓存已清除', style: TextStyle(fontSize: 15)),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: theme.colorScheme.primary,
                                  elevation: 6,
                                  margin: const EdgeInsets.all(12),
                                  action: SnackBarAction(
                                    label: '确定',
                                    textColor: Colors.black,
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            },
                            child: const Text('确认'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // 关于作者区域
  Widget _buildAboutSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          icon: Icons.person,
          title: '关于作者',
          isExpanded: _isAboutExpanded,
          onTap: () {
            setState(() {
              _isAboutExpanded = !_isAboutExpanded;
            });
          },
        ),
        if (_isAboutExpanded) ...[
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Column(
              children: [
                _buildInfoItem(
                  theme,
                  icon: Icons.person_outline,
                  title: '作者',
                  value: AppConfig.authorName,
                ),
                _buildActionItem(
                  theme,
                  icon: Icons.email,
                  title: '联系方式',
                  subtitle: AppConfig.authorEmail,
                  onTap: () => _sendEmail(AppConfig.authorEmail),
                ),
                _buildActionItem(
                  theme,
                  icon: Icons.code,
                  title: 'GitHub',
                  subtitle: '查看项目源码',
                  onTap: () => _launchUrl(AppConfig.githubUrl),
                ),
                _buildActionItem(
                  theme,
                  icon: Icons.volunteer_activism,
                  title: '支持作者',
                  subtitle: '如果您喜欢这个应用',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('支持作者'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('感谢您的支持，您可以通过以下方式支持我：'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSupportButton(
                                  theme,
                                  icon: Icons.star,
                                  label: 'Star项目',
                                  onTap: () => _launchUrl(AppConfig.githubUrl),
                                ),
                                _buildSupportButton(
                                  theme,
                                  icon: Icons.share,
                                  label: '分享应用',
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('分享功能开发中')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('关闭'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // 支持按钮
  Widget _buildSupportButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 信息条目
  Widget _buildInfoItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary.withAlpha(204),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(204),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // 可点击的操作条目
  Widget _buildActionItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary.withAlpha(204),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(230),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withAlpha(102),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required IconData icon,
    required String title,
    bool isExpanded = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null)
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withAlpha(128),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.title,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 25), // 缩进对齐
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withAlpha(26)
                      : theme.colorScheme.onSurface.withAlpha(13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withAlpha(204),
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
              Radio<ThemeMode>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
