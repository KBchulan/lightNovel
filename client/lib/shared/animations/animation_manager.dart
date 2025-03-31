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

  // 动画限制相关
  static final _activeAnimations = <String, DateTime>{};
  static const int maxConcurrentAnimations = 15; // 最大同时动画数
  static const Duration animationTimeout = Duration(seconds: 3); // 动画超时时间

  /// 检查是否可以执行新动画
  static bool canStartNewAnimation(String animationId) {
    _cleanupExpiredAnimations();
    return _activeAnimations.length < maxConcurrentAnimations;
  }

  /// 注册新动画
  static void registerAnimation(String animationId) {
    _activeAnimations[animationId] = DateTime.now();
  }

  /// 注销动画
  static void unregisterAnimation(String animationId) {
    _activeAnimations.remove(animationId);
  }

  /// 清理过期的动画
  static void _cleanupExpiredAnimations() {
    final now = DateTime.now();
    _activeAnimations.removeWhere((id, timestamp) {
      return now.difference(timestamp) > animationTimeout;
    });
  }

  /// 获取当前活跃动画数量
  static int get activeAnimationCount => _activeAnimations.length;

  /// 构建列表项的交错动画
  static Widget buildStaggeredListItem({
    required Widget child,
    required int index,
    bool withAnimation = true,
    AnimationType type = AnimationType.combined,
    Curve? curve,
    Duration? duration,
    String? animationId,
  }) {
    if (!withAnimation) return child;

    final actualAnimationId = animationId ?? 'staggered_$index';
    if (!canStartNewAnimation(actualAnimationId)) {
      return child;
    }

    registerAnimation(actualAnimationId);

    final actualDuration = Duration(
        milliseconds: (duration ?? normalDuration).inMilliseconds +
            (index * maxStaggerDelay).clamp(0, 300));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: actualDuration,
      curve:
          curve ?? (type == AnimationType.scale ? bouncyCurve : defaultCurve),
      onEnd: () => unregisterAnimation(actualAnimationId),
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
    String? animationId,
  }) {
    if (!withAnimation) return child;

    final actualAnimationId =
        animationId ?? 'element_${DateTime.now().millisecondsSinceEpoch}';
    if (!canStartNewAnimation(actualAnimationId)) {
      return child;
    }

    registerAnimation(actualAnimationId);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? normalDuration,
      curve: curve ?? defaultCurve,
      onEnd: () => unregisterAnimation(actualAnimationId),
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
    String? animationId,
  }) {
    final actualAnimationId =
        animationId ?? 'empty_state_${DateTime.now().millisecondsSinceEpoch}';
    if (!canStartNewAnimation(actualAnimationId)) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 24),
          title,
          const SizedBox(height: 10),
          subtitle,
          const SizedBox(height: 28),
          button
        ],
      );
    }

    registerAnimation(actualAnimationId);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 图标动画
        buildAnimatedElement(
          child: icon,
          type: iconAnimationType,
          curve: iconCurve ?? bouncyCurve,
          duration: iconDuration ?? mediumDuration,
          animationId: '${actualAnimationId}_icon',
        ),

        const SizedBox(height: 24),

        // 标题动画
        buildAnimatedElement(
          child: title,
          type: textAnimationType,
          curve: textCurve ?? defaultCurve,
          duration: textDuration ?? normalDuration,
          animationId: '${actualAnimationId}_title',
        ),

        const SizedBox(height: 10),

        // 副标题动画
        buildAnimatedElement(
          child: subtitle,
          type: textAnimationType,
          curve: textCurve ?? defaultCurve,
          duration: textDuration ?? normalDuration,
          animationId: '${actualAnimationId}_subtitle',
        ),

        const SizedBox(height: 28),

        // 按钮动画
        buildAnimatedElement(
          child: button,
          type: buttonAnimationType,
          curve: buttonCurve ?? bouncyCurve,
          duration: buttonDuration ?? normalDuration,
          animationId: '${actualAnimationId}_button',
        ),
      ],
    );
  }

  /// 判断是否应该执行动画
  static bool shouldAnimateAfterDataLoad({
    required bool hasData,
    required bool isLoading,
    required bool hasError,
  }) {
    return hasData && !isLoading && !hasError;
  }
}
