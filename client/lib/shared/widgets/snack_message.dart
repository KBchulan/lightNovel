// ****************************************************************************
//
// @file       snack_message.dart
// @brief      通用消息提示组件
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';

class SnackMessage {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration? duration,
  }) {
    final theme = Theme.of(context);
    
    // 清除当前显示的SnackBar
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: theme.colorScheme.onInverseSurface.withAlpha(31),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: theme.colorScheme.onInverseSurface,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError 
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.inverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: duration ?? const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
} 