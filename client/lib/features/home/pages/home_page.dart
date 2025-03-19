import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/novel_provider.dart';
import '../widgets/novel_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final novelsAsync = ref.watch(novelNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('搜索'),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索小说...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  suffixIcon: const Icon(Icons.search),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    ref.read(novelNotifierProvider.notifier).searchNovels(value);
                  }
                },
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
              children: [
                _buildCategoryChip('全部'),
                _buildCategoryChip('测试1'),
                _buildCategoryChip('测试2'),
                _buildCategoryChip('测试3'),
                _buildCategoryChip('测试4'),
              ],
            ),
          ),
          // 小说列表
          Expanded(
            child: novelsAsync.when(
              data: (novels) => RefreshIndicator(
                onRefresh: () => ref.read(novelNotifierProvider.notifier).refresh(),
                child: GridView.builder(
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
                    Text('加载失败: ${error.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.refresh(novelNotifierProvider);
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

  Widget _buildCategoryChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: false,
        onSelected: (selected) {
          // TODO: 实现分类筛选
        },
      ),
    );
  }
} 