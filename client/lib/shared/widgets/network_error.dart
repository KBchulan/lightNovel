// ****************************************************************************
//
// @file       network_error.dart
// @brief      网络错误页面组件
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';

class NetworkError extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  final bool showPullToRefresh;

  const NetworkError({
    super.key,
    this.message,
    this.onRetry,
    this.showRetryButton = true,
    this.showPullToRefresh = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // 添加一个可拉动区域以触发RefreshIndicator
        if (showPullToRefresh)
          Positioned.fill(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.5),
              ],
            ),
          ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 错误图标动画
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 错误标题
              Text(
                '网络连接失败',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // 错误信息
              if (message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              // 重试按钮
              if (showRetryButton && onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
} 