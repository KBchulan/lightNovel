// ****************************************************************************
//
// @file       search_result_page.dart
// @brief      搜索结果页面
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/novel_provider.dart';
import '../../../shared/widgets/novel_card.dart';
import '../../../shared/animations/page_transitions.dart';
import '../../../shared/animations/animation_manager.dart';
import '../../../features/novel/pages/novel_detail_page.dart';
import '../../../shared/widgets/network_error.dart';
import 'search_box.dart';

class SearchResultPage extends ConsumerStatefulWidget {
  final String keyword;

  const SearchResultPage({
    super.key,
    required this.keyword,
  });

  @override
  ConsumerState<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends ConsumerState<SearchResultPage> {
  bool _shouldShowAnimation = true;

  @override
  void initState() {
    super.initState();
    // 在初始化时执行搜索
    Future.microtask(() {
      ref.read(novelNotifierProvider.notifier).searchNovels(widget.keyword);
    });

    // 延迟关闭动画标记，确保动画完整播放一次
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _shouldShowAnimation = false;
        });
      }
    });
  }

  void handleBack() {
    // 先退出页面，再刷新数据
    Navigator.of(context).pop();
    // 确保使用refresh恢复首页数据
    Future.microtask(() {
      ref.read(novelNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(novelNotifierProvider);

    final shouldAnimate = AnimationManager.shouldAnimateAfterDataLoad(
          hasData: searchResultsAsync.hasValue,
          isLoading: searchResultsAsync.isLoading,
          hasError: searchResultsAsync.hasError,
        ) &&
        _shouldShowAnimation;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          handleBack();
        } else {
          // 如果系统处理了返回（didPop为true），我们也需要确保刷新数据
          Future.microtask(() {
            ref.read(novelNotifierProvider.notifier).refresh();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: SearchBox(
                  hintText: widget.keyword,
                  onSubmitted: (value) {
                    if (value.isNotEmpty && value != widget.keyword) {
                      Navigator.of(context).pushReplacement(
                        SearchResultPageRoute(
                          page: SearchResultPage(keyword: value),
                        ),
                      );
                    }
                  },
                ),
              ),
              TextButton(
                onPressed: handleBack,
                child: const Text('取消'),
              ),
            ],
          ),
          automaticallyImplyLeading: false,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _shouldShowAnimation = true;
            });
            await ref
                .read(novelNotifierProvider.notifier)
                .searchNovels(widget.keyword);
            if (mounted) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {
                    _shouldShowAnimation = false;
                  });
                }
              });
            }
          },
          child: searchResultsAsync.when(
            data: (novels) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimationManager.buildAnimatedElement(
                    withAnimation: shouldAnimate,
                    type: AnimationType.slideUp,
                    duration: AnimationManager.shortDuration,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '"${widget.keyword}" 的搜索结果 (${novels.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: novels.isEmpty
                        ? Center(
                            child: AnimationManager.buildAnimatedElement(
                              withAnimation: shouldAnimate,
                              type: AnimationType.fade,
                              child: const Text('没有找到相关小说'),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: novels.length,
                            itemBuilder: (context, index) {
                              final novel = novels[index];

                              // 基础卡片
                              final card = NovelCard(
                                novel: novel,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    NovelDetailPageRoute(
                                      page: NovelDetailPage(novel: novel),
                                    ),
                                  );
                                },
                              );

                              // 使用动画管理器包装卡片
                              return AnimationManager.buildStaggeredListItem(
                                child: card,
                                index: index,
                                withAnimation: shouldAnimate,
                                type: AnimationType.combined,
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
              onRetry: () {
                ref
                    .read(novelNotifierProvider.notifier)
                    .searchNovels(widget.keyword);
              },
              showPullToRefresh: true,
              showRetryButton: true,
            ),
          ),
        ),
        bottomNavigationBar: const SizedBox(height: 100),
      ),
    );
  }
}
