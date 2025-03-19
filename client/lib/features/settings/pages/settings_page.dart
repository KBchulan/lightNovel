import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 主题设置
          const ListTile(
            title: Text('主题设置'),
            leading: Icon(Icons.palette),
          ),
          ListTile(
            title: const Text('跟随系统'),
            leading: const Icon(Icons.brightness_auto),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: currentThemeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  ref.read(themeNotifierProvider.notifier).setThemeMode(value);
                }
              },
            ),
          ),
          ListTile(
            title: const Text('浅色主题'),
            leading: const Icon(Icons.brightness_high),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: currentThemeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  ref.read(themeNotifierProvider.notifier).setThemeMode(value);
                }
              },
            ),
          ),
          ListTile(
            title: const Text('深色主题'),
            leading: const Icon(Icons.brightness_4),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: currentThemeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  ref.read(themeNotifierProvider.notifier).setThemeMode(value);
                }
              },
            ),
          ),
          const Divider(),
          // 其他设置项可以在这里添加
        ],
      ),
    );
  }
} 