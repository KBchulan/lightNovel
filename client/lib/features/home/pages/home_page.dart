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
import '../../../shared/widgets/page_transitions.dart';
import '../widgets/animated_filter_chip.dart';
import '../../../shared/props/novel_tags.dart';
import '../widgets/search_box.dart';
import '../widgets/search_page.dart';
import '../../novel/pages/novel_detail_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final novelsAsync = ref.watch(novelNotifierProvider);
    final selectedTags = ref.watch(tagFilterProvider);

    return GestureDetector(
      onTap: () {
        // 点击空白处时取消焦点
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
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
        ),
        body: Column(
          children: [
            // 分类导航
            SizedBox(
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
            ),
            // 小说列表
            Expanded(
              child: novelsAsync.when(
                data: (novels) {
                  // 根据选中的标签筛选小说
                  final filteredNovels = selectedTags.contains(NovelTags.all)
                      ? novels
                      : novels.where((novel) {
                          return novel.tags.any((tag) => selectedTags.contains(tag));
                        }).toList();

                  return RefreshIndicator(
                    onRefresh: () => ref.read(novelNotifierProvider.notifier).refresh(),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredNovels.length,
                      itemBuilder: (context, index) {
                        // 倒着排序
                        final novel = filteredNovels[filteredNovels.length - index - 1];
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
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      Text('加载失败: ${error.toString()}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(novelNotifierProvider);
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