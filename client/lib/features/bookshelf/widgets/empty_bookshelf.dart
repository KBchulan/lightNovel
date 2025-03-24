// ****************************************************************************
//
// @file       empty_bookshelf.dart
// @brief      空书架状态组件
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import '../../../shared/animations/animation_manager.dart';

class EmptyBookshelf extends StatelessWidget {
  final VoidCallback onExplore;

  const EmptyBookshelf({
    super.key,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final surfaceColor = colorScheme.surface;

    // 创建图标组件
    final iconWidget = Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(20),
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 书架背景装饰
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(40),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha(20),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),

            // 图标和线条设计
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha(40),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: primaryColor.withAlpha(40),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 36,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );

    // 创建标题文字组件
    final titleWidget = Text(
      '书架空空如也喵～',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );

    // 创建副标题文字组件
    final subtitleWidget = Text(
      '去首页发现好看的小说吧喵！',
      style: TextStyle(
        fontSize: 15,
        color: colorScheme.outline,
        height: 1.4,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.center,
    );

    // 创建按钮组件
    final buttonWidget = FilledButton.icon(
      onPressed: onExplore,
      icon: const Icon(Icons.explore_outlined),
      label: const Text('去探索'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
            horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
      ),
    );

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 使用动画管理器创建所有动画元素
                  AnimationManager.buildEmptyStateAnimation(
                    context: context,
                    icon: iconWidget,
                    title: titleWidget,
                    subtitle: subtitleWidget,
                    button: buttonWidget,
                    iconAnimationType: AnimationType.scale,
                    textAnimationType: AnimationType.slideUp,
                    buttonAnimationType: AnimationType.scale,
                    iconDuration: AnimationManager.mediumDuration,
                    textDuration: AnimationManager.normalDuration,
                    buttonDuration: AnimationManager.normalDuration,
                    iconCurve: AnimationManager.bouncyCurve,
                  ),

                  const SizedBox(height: 36),

                  // 底部装饰元素
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDecorativeElement(5, primaryColor.withAlpha(100)),
                      const SizedBox(width: 10),
                      _buildDecorativeElement(6, primaryColor.withAlpha(120)),
                      const SizedBox(width: 10),
                      _buildDecorativeElement(5, primaryColor.withAlpha(100)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeElement(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
