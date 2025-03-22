// ****************************************************************************
//
// @file       slide_animation.dart
// @brief      滑动动画组件
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';

enum SlideDirection {
  fromTop,
  fromBottom,
}

class SlideAnimation extends StatefulWidget {
  final Widget child;
  final SlideDirection direction;
  final Duration duration;
  final bool show;

  const SlideAnimation({
    super.key,
    required this.child,
    required this.direction,
    this.duration = const Duration(milliseconds: 300),
    this.show = true,
  });

  @override
  State<SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _updateAnimation();

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SlideAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
    if (widget.show) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _updateAnimation() {
    final begin = widget.direction == SlideDirection.fromTop
        ? const Offset(0.0, -1.0)
        : const Offset(0.0, 1.0);
    const end = Offset.zero;

    _offsetAnimation = Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
} 