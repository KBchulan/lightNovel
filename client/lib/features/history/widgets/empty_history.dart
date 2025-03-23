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

// 定义历史页面切换到首页的通知
class SwitchToHomeFromHistoryNotification extends Notification {}

class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final surfaceColor = colorScheme.surface;
    
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 精美的图标设计
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(30),
                  borderRadius: BorderRadius.circular(70),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 书本背景装饰
                      Container(
                        width: 94,
                        height: 94,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(50),
                          borderRadius: BorderRadius.circular(47),
                        ),
                      ),
                      
                      // 图标和线条设计
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withAlpha(30),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: primaryColor.withAlpha(30),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 36,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 标题文字
              Text(
                '还没有阅读记录喵～',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // 副标题描述
              Text(
                '去首页找本喜欢的小说开始阅读吧喵！',
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.outline,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // 简洁的发现按钮
              FilledButton.icon(
                onPressed: () {
                  debugPrint('我被点击了');
                  // 发送通知
                  SwitchToHomeFromHistoryNotification().dispatch(context);
                },
                icon: const Icon(Icons.explore_outlined),
                label: const Text('浏览小说'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // 底部装饰元素
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDecorativeElement(4, primaryColor.withAlpha(80)),
                  const SizedBox(width: 8),
                  _buildDecorativeElement(6, primaryColor.withAlpha(100)),
                  const SizedBox(width: 8),
                  _buildDecorativeElement(4, primaryColor.withAlpha(80)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDecorativeElement(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
} 