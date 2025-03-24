// ****************************************************************************
//
// @file       animation_manager.dart
// @brief      统一动画管理器
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';

// 动画类型
enum AnimationType {
  fade,
  scale,
  slideUp,
  slideDown,
  slideHorizontal,
  combined
}

/// 统一动画管理器
/// 提供全局一致的动画效果，取代散落在各个页面的动画逻辑
class AnimationManager {
  // 动画曲线
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.easeOutBack;
  static const Curve fastOutSlowInCurve = Curves.fastOutSlowIn;

  // 动画时长
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration mediumDuration = Duration(milliseconds: 400);
  static const Duration longDuration = Duration(milliseconds: 500);

  // 最大延迟时间，确保动画不会过长
  static const int maxStaggerDelay = 50;

  /// 构建列表项的交错动画
  static Widget buildStaggeredListItem({
    required Widget child,
    required int index,
    bool withAnimation = true,
    AnimationType type = AnimationType.combined,
    Curve? curve,
    Duration? duration,
  }) {
    if (!withAnimation) return child;

    final actualDuration = Duration(
        milliseconds: (duration ?? normalDuration).inMilliseconds +
            (index * maxStaggerDelay).clamp(0, 300));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: actualDuration,
      curve:
          curve ?? (type == AnimationType.scale ? bouncyCurve : defaultCurve),
      builder: (context, value, _) {
        switch (type) {
          case AnimationType.fade:
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            );
          case AnimationType.scale:
            return Transform.scale(
              scale: 0.7 + (0.3 * value),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          case AnimationType.slideUp:
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          case AnimationType.slideDown:
            return Transform.translate(
              offset: Offset(0, -30 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          case AnimationType.slideHorizontal:
            return Transform.translate(
              offset: Offset(50 * (1 - value), 0),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          case AnimationType.combined:
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Transform.scale(
                scale: 0.9 + (0.1 * value),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
        }
      },
      child: child,
    );
  }

  /// 构建简单的单个元素动画
  static Widget buildAnimatedElement({
    required Widget child,
    bool withAnimation = true,
    AnimationType type = AnimationType.fade,
    Curve? curve,
    Duration? duration,
    double? startScale,
    double? endScale,
    Offset? startOffset,
    Offset? endOffset = Offset.zero,
  }) {
    if (!withAnimation) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? normalDuration,
      curve: curve ?? defaultCurve,
      builder: (context, value, _) {
        switch (type) {
          case AnimationType.fade:
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            );
          case AnimationType.scale:
            final actualStartScale = startScale ?? 0.8;
            final actualEndScale = endScale ?? 1.0;
            final scale = actualStartScale +
                ((actualEndScale - actualStartScale) * value);

            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          case AnimationType.slideUp:
            final actualStartOffset = startOffset ?? const Offset(0, 30);
            return Transform.translate(
              offset: Offset(
                actualStartOffset.dx * (1 - value),
                actualStartOffset.dy * (1 - value),
              ),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          case AnimationType.slideDown:
            final actualStartOffset = startOffset ?? const Offset(0, -30);
            return Transform.translate(
              offset: Offset(
                actualStartOffset.dx * (1 - value),
                actualStartOffset.dy * (1 - value),
              ),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          case AnimationType.slideHorizontal:
            final actualStartOffset = startOffset ?? const Offset(50, 0);
            return Transform.translate(
              offset: Offset(
                actualStartOffset.dx * (1 - value),
                actualStartOffset.dy * (1 - value),
              ),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          case AnimationType.combined:
            final actualStartScale = startScale ?? 0.9;
            final actualEndScale = endScale ?? 1.0;
            final scale = actualStartScale +
                ((actualEndScale - actualStartScale) * value);
            final actualStartOffset = startOffset ?? const Offset(0, 20);

            return Transform.translate(
              offset: Offset(
                actualStartOffset.dx * (1 - value),
                actualStartOffset.dy * (1 - value),
              ),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
        }
      },
    );
  }

  /// 构建空态页面的动画组件
  static Widget buildEmptyStateAnimation({
    required Widget icon,
    required Widget title,
    required Widget subtitle,
    required Widget button,
    required BuildContext context,
    AnimationType iconAnimationType = AnimationType.scale,
    AnimationType textAnimationType = AnimationType.slideUp,
    AnimationType buttonAnimationType = AnimationType.scale,
    Duration? iconDuration,
    Duration? textDuration,
    Duration? buttonDuration,
    Curve? iconCurve,
    Curve? textCurve,
    Curve? buttonCurve,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 图标动画
        buildAnimatedElement(
          child: icon,
          type: iconAnimationType,
          curve: iconCurve ?? bouncyCurve,
          duration: iconDuration ?? mediumDuration,
        ),

        const SizedBox(height: 24),

        // 标题动画
        buildAnimatedElement(
          child: title,
          type: textAnimationType,
          curve: textCurve ?? defaultCurve,
          duration: textDuration ?? normalDuration,
        ),

        const SizedBox(height: 10),

        // 副标题动画
        buildAnimatedElement(
          child: subtitle,
          type: textAnimationType,
          curve: textCurve ?? defaultCurve,
          duration: textDuration ?? normalDuration,
        ),

        const SizedBox(height: 28),

        // 按钮动画
        buildAnimatedElement(
          child: button,
          type: buttonAnimationType,
          curve: buttonCurve ?? bouncyCurve,
          duration: buttonDuration ?? normalDuration,
        ),
      ],
    );
  }

  /// 判断是否应该执行动画
  /// 用于避免在数据未加载完成时执行动画造成闪烁
  static bool shouldAnimateAfterDataLoad({
    required bool hasData,
    required bool isLoading,
    required bool hasError,
  }) {
    return hasData && !isLoading && !hasError;
  }
}
