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
import '../../../core/providers/search_result_provider.dart';
import '../../../shared/widgets/novel_card.dart';
import 'search_box.dart';

class SearchResultPage extends ConsumerWidget {
  final String keyword;

  const SearchResultPage({
    super.key,
    required this.keyword,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResultsAsync = ref.watch(searchResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: SearchBox(
                hintText: keyword,
                onSubmitted: (value) {
                  if (value.isNotEmpty && value != keyword) {
                    ref.read(searchResultProvider.notifier).search(value);
                  }
                },
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(searchResultProvider.notifier).clear();
                Navigator.pop(context);
              },
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
                '"$keyword" 的搜索结果 (${novels.length})',
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                            // TODO: 导航到小说详情页
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
                        ref.read(searchResultProvider.notifier).search(keyword);
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
    );
  }
} 