// ****************************************************************************
//
// @file       main_page.dart
// @brief      主页
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/pages/home_page.dart';
import '../../bookshelf/pages/bookshelf_page.dart';
import '../../history/pages/history_page.dart';
import '../../settings/pages/settings_page.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 0;

  static final List<({Widget page, _NavigationItemData item})> _items = [
    (
      page: const HomePage(),
      item: const _NavigationItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: '首页',
      ),
    ),
    (
      page: const BookshelfPage(),
      item: const _NavigationItemData(
        icon: Icons.book_outlined,
        activeIcon: Icons.book_rounded,
        label: '书架',
      ),
    ),
    (
      page: const HistoryPage(),
      item: const _NavigationItemData(
        icon: Icons.history_outlined,
        activeIcon: Icons.history_rounded,
        label: '历史',
      ),
    ),
    (
      page: const SettingsPage(),
      item: const _NavigationItemData(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: '设置',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => NotificationListener<SwitchToHomeNotification>(
              onNotification: (notification) {
                setState(() => _currentIndex = 0);
                return true;
              },
              child: _items[_currentIndex].page,
            ),
            settings: settings,
          );
        },
        // ignore: deprecated_member_use
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }
          return true;
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (index) {
                final item = _items[index].item;
                final isSelected = _currentIndex == index;

                return _NavigationBarItem(
                  icon: item.icon,
                  activeIcon: item.activeIcon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () {
                    if (_currentIndex != index) {
                      setState(() => _currentIndex = index);
                    }
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationBarItem extends StatelessWidget {
  const _NavigationBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withAlpha(128);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
              curve: Curves.easeOutCubic,
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 1.0 + (value * 0.1),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isSelected ? primaryColor : inactiveColor,
                        isSelected ? primaryColor.withAlpha(230) : inactiveColor,
                      ],
                    ).createShader(bounds),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
              curve: Curves.easeOutCubic,
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Color.lerp(inactiveColor, primaryColor, value),
                    fontWeight: FontWeight.lerp(
                      FontWeight.normal,
                      FontWeight.w600,
                      value,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItemData {
  const _NavigationItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
