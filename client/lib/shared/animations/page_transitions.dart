// ****************************************************************************
//
// @file       page_transitions.dart
// @brief      自定义页面切换动画
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';

abstract class BasePageRoute<T> extends PageRouteBuilder<T> {
  static const defaultDuration = Duration(milliseconds: 300);
  static const fastDuration = Duration(milliseconds: 200);
  static const defaultCurve = Curves.easeOutCubic;

  final Widget page;

  BasePageRoute({
    required this.page,
    required super.transitionsBuilder,
    Duration duration = defaultDuration,
    Duration? reverseDuration,
    super.opaque,
    super.barrierColor,
    super.maintainState,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration ?? duration,
        );
}

/// 从下方滑入的页面路由
class SlideUpPageRoute<T> extends BasePageRoute<T> {
  SlideUpPageRoute({
    required super.page,
  }) : super(
          duration: BasePageRoute.fastDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.05);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}

/// 从右侧滑入的页面路由
class SlideHorizontalPageRoute<T> extends BasePageRoute<T> {
  SlideHorizontalPageRoute({
    required super.page,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;

            var tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: BasePageRoute.defaultCurve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

/// 淡入淡出页面路由
class FadePageRoute<T> extends BasePageRoute<T> {
  FadePageRoute({
    required super.page,
  }) : super(
          duration: BasePageRoute.fastDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// 缩放页面路由
class ScalePageRoute<T> extends BasePageRoute<T> {
  ScalePageRoute({
    required super.page,
  }) : super(
          duration: BasePageRoute.fastDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOut;
            var scaleTween =
                Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: curve));
            var opacityTween =
                Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: curve));

            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(opacityTween),
                child: child,
              ),
            );
          },
        );
}

/// 共享元素过渡路由
class SharedAxisPageRoute<T> extends BasePageRoute<T> {
  final SharedAxisTransitionType type;
  final bool reverse;

  SharedAxisPageRoute({
    required super.page,
    this.type = SharedAxisTransitionType.horizontal,
    this.reverse = false,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Widget transitionChild = child;

            switch (type) {
              case SharedAxisTransitionType.horizontal:
                // 支持反向动画（从左向右）
                var slideAnimation = Tween(
                  begin: Offset(reverse ? -1.0 : 1.0, 0.0),
                  end: Offset.zero,
                )
                    .chain(CurveTween(curve: BasePageRoute.defaultCurve))
                    .animate(animation);
                transitionChild = SlideTransition(
                  position: slideAnimation,
                  child: child,
                );
                break;
              case SharedAxisTransitionType.scaled:
                var scaleAnimation = Tween(
                  begin: 0.9,
                  end: 1.0,
                )
                    .chain(CurveTween(curve: BasePageRoute.defaultCurve))
                    .animate(animation);
                transitionChild = ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                );
                break;
              case SharedAxisTransitionType.fade:
                transitionChild = FadeTransition(
                  opacity: animation,
                  child: child,
                );
                break;
            }

            return transitionChild;
          },
        );
}

/// 书本打开/关闭动画路由
class BookPageRoute<T> extends BasePageRoute<T> {
  final bool reverse;

  BookPageRoute({
    required super.page,
    this.reverse = false,
  }) : super(
          duration: const Duration(milliseconds: 400),
          reverseDuration: const Duration(milliseconds: 400),
          opaque: true,
          barrierColor: Colors.transparent,
          maintainState: true,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var slideAnimation = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve))
                .animate(animation);

            var scaleAnimation = Tween(begin: 0.7, end: 1.0)
                .chain(CurveTween(curve: curve))
                .animate(animation);

            var rotateAnimation =
                Tween(begin: reverse ? 0.0 : 0.1, end: reverse ? -0.1 : 0.0)
                    .chain(CurveTween(curve: curve))
                    .animate(animation);

            return Transform(
              alignment: reverse ? Alignment.centerRight : Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(rotateAnimation.value)
                ..scale(scaleAnimation.value),
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        );
}

/// 搜索结果页面过渡动画
class SearchResultPageRoute<T> extends BasePageRoute<T> {
  SearchResultPageRoute({
    required super.page,
  }) : super(
          duration: const Duration(milliseconds: 250),
          reverseDuration: const Duration(milliseconds: 200),
          opaque: true,
          barrierColor: Colors.transparent,
          maintainState: true,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 定义更平滑的动画曲线
            const curve = Curves.easeOutQuart;
            const reverseCurve = Curves.easeInQuart;

            // 主页面进入动画
            var slideAnimation = Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            // 主页面透明度动画
            var fadeAnimation = Tween(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            // 前一页面退出动画
            var secondaryFadeAnimation = Tween(
              begin: 1.0,
              end: 0.4,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: reverseCurve,
            ));

            // 为前一页面添加轻微缩放效果，使过渡更自然
            var secondaryScaleAnimation = Tween(
              begin: 1.0,
              end: 0.95,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: reverseCurve,
            ));

            return Stack(
              children: [
                // 前一页面
                FadeTransition(
                  opacity: secondaryFadeAnimation,
                  child: ScaleTransition(
                    scale: secondaryScaleAnimation,
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
                // 当前页面
                SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
}

/// 小说详情页面过渡动画
class NovelDetailPageRoute<T> extends BasePageRoute<T> {
  final bool isReverse;

  NovelDetailPageRoute({
    required super.page,
    this.isReverse = false,
  }) : super(
          duration: BasePageRoute.defaultDuration,
          reverseDuration: BasePageRoute.fastDuration,
          opaque: false,
          barrierColor: Colors.transparent,
          maintainState: true,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var scaleAnimation = Tween(
              begin: isReverse ? 1.0 : 0.95,
              end: isReverse ? 0.95 : 1.0,
            )
                .chain(CurveTween(curve: BasePageRoute.defaultCurve))
                .animate(animation);

            var fadeAnimation = Tween(
              begin: isReverse ? 1.0 : 0.3,
              end: isReverse ? 0.3 : 1.0,
            )
                .chain(CurveTween(curve: BasePageRoute.defaultCurve))
                .animate(animation);

            var secondaryScaleAnimation = Tween(
              begin: isReverse ? 0.95 : 1.0,
              end: isReverse ? 1.0 : 0.95,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: BasePageRoute.defaultCurve,
            ));

            return Stack(
              children: [
                ScaleTransition(
                  scale: secondaryScaleAnimation,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
                FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
}

/// 章节切换页面过渡动画
class ChapterTransitionRoute<T> extends BasePageRoute<T> {
  final bool isNext;

  ChapterTransitionRoute({
    required super.page,
    this.isNext = true,
  }) : super(
          duration: const Duration(milliseconds: 400),
          reverseDuration: const Duration(milliseconds: 400),
          opaque: true,
          barrierColor: Colors.transparent,
          maintainState: true,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 定义动画曲线
            const curve = Curves.easeInOutCubic;

            // 主页面进入动画
            var slideAnimation = Tween(
              begin: Offset(isNext ? 1.0 : -1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            // 主页面透明度动画
            var fadeAnimation = Tween(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            // 前一页面退出动画
            var secondarySlideAnimation = Tween(
              begin: Offset.zero,
              end: Offset(isNext ? -1.0 : 1.0, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: curve,
            ));

            // 前一页面透明度动画
            var secondaryFadeAnimation = Tween(
              begin: 1.0,
              end: 0.0,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: curve,
            ));

            return Stack(
              children: [
                // 前一页面
                SlideTransition(
                  position: secondarySlideAnimation,
                  child: FadeTransition(
                    opacity: secondaryFadeAnimation,
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
                // 当前页面
                SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
}

enum SharedAxisTransitionType {
  horizontal,
  scaled,
  fade,
}
