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
import '../../../shared/widgets/page_transitions.dart';
import '../../../features/novel/pages/novel_detail_page.dart';
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
  @override
  void initState() {
    super.initState();
    // 在初始化时执行搜索
    Future.microtask(() {
      ref.read(novelNotifierProvider.notifier).searchNovels(widget.keyword);
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: searchResultsAsync.when(
                data: (novels) => Text(
                  '"${widget.keyword}" 的搜索结果 (${novels.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const Text('搜索中...'),
                error: (_, __) => const Text('搜索失败'),
              ),
            ),
            Expanded(
              child: searchResultsAsync.when(
                data: (novels) => novels.isEmpty
                    ? const Center(
                        child: Text('没有找到相关小说'),
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
                          return NovelCard(
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
                        },
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      Text('搜索失败: ${error.toString()}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(novelNotifierProvider.notifier)
                              .searchNovels(widget.keyword);
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
