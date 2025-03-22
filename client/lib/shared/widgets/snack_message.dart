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
                color: (isError 
                    ? theme.colorScheme.error 
                    : theme.colorScheme.primary).withAlpha(31),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError 
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        duration: duration ?? const Duration(milliseconds: 500),
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }
} 