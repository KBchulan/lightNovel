// ****************************************************************************
//
// @file       bookmark_sheet.dart
// @brief      书签功能底部弹出组件
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';

class BookmarkSheet extends StatelessWidget {
  const BookmarkSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '书签功能开发中...',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
} 