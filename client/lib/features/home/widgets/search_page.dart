// ****************************************************************************
//
// @file       search_page.dart
// @brief      搜索页面
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/search_history_provider.dart';
import '../../../core/providers/novel_provider.dart';
import '../../../shared/widgets/page_transitions.dart';
import 'search_box.dart';
import 'search_result_page.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  void _handleSearch(BuildContext context, WidgetRef ref, String value) {
    if (value.isEmpty) return;

    ref.read(searchHistoryProvider.notifier).addSearch(value);

    // 先将状态设置为loading，但不执行实际搜索
    ref.read(novelNotifierProvider.notifier).setLoading();

    // 导航到搜索结果页面
    Navigator.of(context).push(
      SearchResultPageRoute(
        page: SearchResultPage(keyword: value),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchHistoryAsync = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: SearchBox(
                autofocus: true,
                onSubmitted: (value) => _handleSearch(context, ref, value),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: searchHistoryAsync.when(
        data: (searchHistory) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (searchHistory.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '搜索历史',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        ref.read(searchHistoryProvider.notifier).clearHistory();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: searchHistory.length,
                  itemBuilder: (context, index) {
                    final keyword = searchHistory[index];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(keyword),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          ref
                              .read(searchHistoryProvider.notifier)
                              .removeSearch(keyword);
                        },
                      ),
                      onTap: () => _handleSearch(context, ref, keyword),
                    );
                  },
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text('暂无搜索历史'),
                ),
              ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('加载搜索历史失败: $error'),
        ),
      ),
    );
  }
}
