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

/// 从下方滑入的页面路由
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.05);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        );
}

/// 从右侧滑入的页面路由
class SlideHorizontalPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideHorizontalPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// 淡入淡出页面路由
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        );
}

/// 缩放页面路由
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScalePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOut;
            var scaleTween = Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: curve));
            var opacityTween = Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: curve));

            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(opacityTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        );
}

/// 共享元素过渡路由
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SharedAxisTransitionType type;

  SharedAxisPageRoute({
    required this.page,
    this.type = SharedAxisTransitionType.horizontal,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var slideAnimation = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve))
                .animate(animation);

            var scaleAnimation = Tween(begin: 0.9, end: 1.0)
                .chain(CurveTween(curve: curve))
                .animate(animation);

            Widget transitionChild = child;

            switch (type) {
              case SharedAxisTransitionType.horizontal:
                transitionChild = SlideTransition(
                  position: slideAnimation,
                  child: child,
                );
                break;
              case SharedAxisTransitionType.scaled:
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
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// 书本打开/关闭动画路由
class BookPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool reverse;

  BookPageRoute({
    required this.page,
    this.reverse = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
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

            var rotateAnimation = Tween(begin: reverse ? 0.0 : 0.1, end: reverse ? -0.1 : 0.0)
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
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
        );
}

/// 搜索结果页面过渡动画
class SearchResultPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SearchResultPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var curve = Curves.easeOutCubic;
            
            // 主页面的动画
            var slideAnimation = Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            // 背景页面动画
            var secondarySlideAnimation = Tween(
              begin: Offset.zero,
              end: const Offset(-0.2, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: curve,
            ));

            return Stack(
              fit: StackFit.passthrough,
              children: [
                // 背景页面动画
                SlideTransition(
                  position: secondarySlideAnimation,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
                
                // 主页面动画
                SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              ],
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          opaque: false,
          barrierColor: Colors.transparent,
          maintainState: true,
        );
}

/// 小说详情页面过渡动画
class NovelDetailPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool isReverse;

  NovelDetailPageRoute({
    required this.page,
    this.isReverse = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var curve = Curves.easeOutCubic;
            
            // 缩放动画
            var scaleAnimation = Tween(
              begin: isReverse ? 1.0 : 0.95,
              end: isReverse ? 0.95 : 1.0,
            ).chain(CurveTween(curve: curve)).animate(animation);

            // 淡入动画
            var fadeAnimation = Tween(
              begin: isReverse ? 1.0 : 0.3,
              end: isReverse ? 0.3 : 1.0,
            ).chain(CurveTween(curve: curve)).animate(animation);

            // 背景页面动画
            var secondaryScaleAnimation = Tween(
              begin: isReverse ? 0.95 : 1.0,
              end: isReverse ? 1.0 : 0.95,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: curve,
            ));

            return Stack(
              children: [
                // 背景页面动画
                ScaleTransition(
                  scale: secondaryScaleAnimation,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
                
                // 主内容动画
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
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          opaque: false,
          barrierColor: Colors.transparent,
          maintainState: true,
        );
}

enum SharedAxisTransitionType {
  horizontal,
  scaled,
  fade,
} 