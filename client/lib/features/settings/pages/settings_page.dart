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
import 'dart:async';

import '../../../core/theme/app_theme.dart';
import '../../../config/app_config.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/models/models.dart';

class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.onTap,
    this.size = 80,
  });

  final String avatarUrl;
  final VoidCallback onTap;
  final double size;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _cachedAvatarUrl;
  bool _isDefaultAvatar = false;
  bool _useIconFallback = false;

  @override
  void initState() {
    super.initState();
    _updateCachedUrl();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
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
  bool _isLoading = false;

  // 用户名编辑控制器
  final TextEditingController _nameController = TextEditingController();

  // 添加编辑状态控制
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 加载用户资料
  Future<void> _loadUserProfile() async {
    if (_isLoading) return;

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
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      try {
        final apiClient = ref.read(apiClientProvider);
        final updatedUser = await apiClient.uploadAvatarAndUpdateProfile(
          File(image.path),
        );

        if (mounted) {
          setState(() {
            _user = updatedUser;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('头像更新失败: $e')),
          );
        }
      }
    }
  }

  // 开始编辑用户名
  void _startEditingName() {
    setState(() {
      _isEditingName = true;
      _nameController.text = _user?.name ?? '';
    });
  }

  // 取消编辑用户名
  void _cancelEditingName() {
    setState(() {
      _isEditingName = false;
      _nameController.text = '';
    });
  }

  // 修改用户名
  Future<void> _updateUsername() async {
    if (_user == null) return;

    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户名不能为空')),
      );
      return;
    }

    if (newName == _user!.name) {
      setState(() {
        _isEditingName = false;
      });
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final updatedUser = await apiClient.updateUserProfile(
        name: newName,
      );

      setState(() {
        _user = updatedUser;
        _isEditingName = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('用户名修改失败: $e')),
        );
      }
    }
  }

  // 打开URL链接
  Future<void> _launchUrl(String url) async {
    if (!mounted) return;

    try {
      final uri = Uri.parse(url);
      if (!await url_launcher.launchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无法打开链接: $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开链接失败: $e')),
        );
      }
    }
  }

  // 发送邮件
  Future<void> _sendEmail(String email) async {
    if (!mounted) return;

    try {
      final uri = Uri.parse('mailto:$email?subject=${AppConfig.appName}用户反馈');
      if (!await url_launcher.launchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开邮件客户端')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送邮件失败: $e')),
        );
      }
    }
  }

  // 主题切换处理
  void _handleThemeChange(ThemeMode? value) {
    if (value == null) return;

    final notifier = ref.read(themeNotifierProvider.notifier);
    final currentThemeMode = ref.read(themeNotifierProvider);

    if (value == currentThemeMode) return;

    // 为主题切换添加视觉反馈
    final targetMode = value;

    // 启用平滑过渡
    notifier.setThemeMode(targetMode);
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
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : (_user != null
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        children: [
                          // 用户信息行
                          Row(
                            children: [
                              // 头像
                              GestureDetector(
                                onTap: _pickAndUploadAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withAlpha(50),
                                      width: 2,
                                    ),
                                  ),
                                  child: UserAvatar(
                                    avatarUrl: _user!.avatar,
                                    onTap: _pickAndUploadAvatar,
                                    size: 52,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // 用户名
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _isEditingName
                                          ? Container(
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme
                                                    .surfaceContainerHighest
                                                    .withAlpha(125),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: TextField(
                                                controller: _nameController,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  isDense: true,
                                                  hintText: '请输入新的用户名',
                                                  hintStyle: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    color: theme
                                                        .colorScheme.onSurface
                                                        .withAlpha(128),
                                                  ),
                                                ),
                                                maxLength: 20,
                                                buildCounter: (context,
                                                        {required currentLength,
                                                        required isFocused,
                                                        maxLength}) =>
                                                    null,
                                                onSubmitted: (value) {
                                                  if (value.trim().isNotEmpty) {
                                                    _updateUsername();
                                                  }
                                                },
                                                autofocus: true,
                                              ),
                                            )
                                          : Text(
                                              _user?.name ?? '',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                    ),
                                    if (_isEditingName)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: _cancelEditingName,
                                            icon: Icon(
                                              Icons.close,
                                              color: theme.colorScheme.error
                                                  .withAlpha(230),
                                              size: 18,
                                            ),
                                            tooltip: '取消',
                                            style: IconButton.styleFrom(
                                              padding: const EdgeInsets.all(8),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              if (_nameController.text
                                                  .trim()
                                                  .isNotEmpty) {
                                                _updateUsername();
                                              }
                                            },
                                            icon: Icon(
                                              Icons.check,
                                              color: theme.colorScheme.primary
                                                  .withAlpha(230),
                                              size: 18,
                                            ),
                                            tooltip: '保存',
                                            style: IconButton.styleFrom(
                                              padding: const EdgeInsets.all(8),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      IconButton(
                                        onPressed: _startEditingName,
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: theme.colorScheme.primary
                                              .withAlpha(230),
                                          size: 18,
                                        ),
                                        tooltip: '修改用户名',
                                        style: IconButton.styleFrom(
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // 提示文本
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8, right: 4),
                              child: Text(
                                '后续会有更多个性化选项',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(115),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text('获取用户资料失败')),
                    )),
          crossFadeState: _isUserExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeOutCubic,
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeOutCubic,
        ),
      ],
    );
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
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: Column(
            children: [
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
          ),
          crossFadeState: _isThemeExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeOutCubic,
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeOutCubic,
        ),
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
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: Padding(
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
                        content: const Text('当前已是最新版本',
                            style: TextStyle(fontSize: 15)),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                                  content: const Text('缓存已清除',
                                      style: TextStyle(fontSize: 15)),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
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
                const SizedBox(height: 8),
              ],
            ),
          ),
          crossFadeState: _isAppExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeOutCubic,
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeOutCubic,
        ),
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
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: Padding(
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
                const SizedBox(height: 8),
              ],
            ),
          ),
          crossFadeState: _isAboutExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeOutCubic,
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeOutCubic,
        ),
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withAlpha(isExpanded ? 40 : 26),
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
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.chevron_right,
                    color: isExpanded
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withAlpha(128),
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withAlpha(26)
                      : theme.colorScheme.onSurface.withAlpha(13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    icon,
                    size: 18,
                    key: ValueKey<bool>(isSelected),
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withAlpha(204),
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                  child: Text(title),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Radio<ThemeMode>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
