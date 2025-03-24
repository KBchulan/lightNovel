// ****************************************************************************
//
// @file       home_page.dart
// @brief      主页
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/novel_provider.dart';
import '../../../core/providers/tag_filter_provider.dart';
import '../../../shared/widgets/novel_card.dart';
import '../../../shared/animations/page_transitions.dart';
import '../../../shared/animations/animation_manager.dart';
import '../widgets/animated_filter_chip.dart';
import '../../../shared/props/novel_tags.dart';
import '../widgets/search_box.dart';
import '../widgets/search_page.dart';
import '../../novel/pages/novel_detail_page.dart';
import '../../../shared/widgets/network_error.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _shouldShowAnimation = true;
  
  @override
  void initState() {
    super.initState();
  }

  // 处理刷新操作
  Future<void> _handleRefresh() async {
    // 标记为刷新状态，以便触发动画
    setState(() {
      _shouldShowAnimation = true;
    });
    
    // 等待数据刷新完成
    await ref.read(novelNotifierProvider.notifier).refresh();
    
    // 延迟重置动画状态，确保动画有足够时间完成
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _shouldShowAnimation = false;
      });
    }
  }

  // 处理重试操作
  Future<void> _handleRetry() async {
    // 标记为刷新状态，以便触发动画
    setState(() {
      _shouldShowAnimation = true;
    });
    
    // 等待数据刷新完成
    await ref.read(novelNotifierProvider.notifier).refresh();
    
    // 延迟重置动画状态，确保动画有足够时间完成
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _shouldShowAnimation = false;
      });
    }
  }

  // 构建AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Text('首页'),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  FadePageRoute(
                    page: const SearchPage(),
                  ),
                );
              },
              child: AbsorbPointer(
                child: SearchBox(
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      ref.read(novelNotifierProvider.notifier).searchNovels(value);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建标签栏
  Widget _buildTagBar(Set<String> selectedTags) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: NovelTags.allTags.map((tag) {
          return AnimatedFilterChip(
            label: tag,
            selected: selectedTags.contains(tag),
            onSelected: (_) {
              ref.read(tagFilterProvider.notifier).toggleTag(tag);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final novelsAsync = ref.watch(novelNotifierProvider);
    final selectedTags = ref.watch(tagFilterProvider);

    // 数据加载完成后延迟关闭动画标记
    if (novelsAsync.hasValue && _shouldShowAnimation) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _shouldShowAnimation = false;
          });
        }
      });
    }

    final shouldAnimate = AnimationManager.shouldAnimateAfterDataLoad(
      hasData: novelsAsync.hasValue,
      isLoading: novelsAsync.isLoading,
      hasError: novelsAsync.hasError,
    ) && _shouldShowAnimation;

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: novelsAsync.when(
          data: (novels) {
            // 根据选中的标签筛选小说
            final filteredNovels = selectedTags.contains(NovelTags.all)
                ? novels
                : novels.where((novel) {
                    return novel.tags
                        .any((tag) => selectedTags.contains(tag));
                  }).toList();

            return Column(
              children: [
                // A. 分类导航
                _buildTagBar(selectedTags),
                
                // 小说列表
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredNovels.length,
                    itemBuilder: (context, index) {
                      // 倒着排序
                      final novel =
                          filteredNovels[filteredNovels.length - index - 1];
                          
                      // 基础卡片
                      final card = NovelCard(
                        novel: novel,
                        onTap: () {
                          Navigator.push(
                            context,
                            NovelDetailPageRoute(page: NovelDetailPage(novel: novel)),
                          );
                        },
                      );
                      
                      // 使用动画管理器包装卡片
                      return AnimationManager.buildStaggeredListItem(
                        child: card,
                        index: index,
                        withAnimation: shouldAnimate,
                        type: AnimationType.combined,
                        duration: AnimationManager.normalDuration,
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => NetworkError(
            message: error.toString(),
            onRetry: _handleRetry,
            showPullToRefresh: true,
          ),
        ),
      ),
    );
  }
}
