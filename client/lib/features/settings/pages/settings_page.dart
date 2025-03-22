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
import '../../../core/theme/app_theme.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isThemeExpanded = false;

  Future<void> _handleThemeChange(ThemeMode? value) async {
    if (value != null) {
      final currentThemeMode = ref.read(themeNotifierProvider);
      // 如果切换到当前系统主题，直接切换
      if (value == ThemeMode.system) {
        ref.read(themeNotifierProvider.notifier).setThemeMode(value);
        return;
      }
      // 如果切换到与当前主题相同的模式，不执行动画
      if (value == currentThemeMode) {
        return;
      }
      // 其他情况执行动画切换
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
          // 主题设置
          _buildThemeSection(theme, currentThemeMode),
        ],
      ),
    );
  }

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
        ],
      ],
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.onSurface,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            children: [
              const SizedBox(width: 40), // 缩进对齐
              Icon(
                icon,
                size: 24,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withAlpha(179),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withAlpha(179),
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
              Radio<ThemeMode>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
