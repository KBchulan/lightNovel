// ****************************************************************************
//
// @file       empty_history.dart
// @brief      空历史记录状态组件
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';

class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final outlineColor = colorScheme.outline;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 64,
              color: outlineColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '这里还没有阅读记录喵～',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '去首页找本喜欢的小说开始阅读吧喵！',
            style: TextStyle(
              fontSize: 14,
              color: Color.alphaBlend(
                outlineColor.withAlpha(179),
                colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 