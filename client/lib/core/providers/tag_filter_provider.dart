// ****************************************************************************
//
// @file       tag_filter_provider.dart
// @brief      标签筛选状态管理
//
// @author     KBchulan
// @date       2025/03/19
// @history    
// ****************************************************************************

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../shared/props/novel_tags.dart';

part 'tag_filter_provider.g.dart';

@riverpod
class TagFilter extends _$TagFilter {
  @override
  Set<String> build() {
    return {NovelTags.all};
  }

  void toggleTag(String tag) {
    if (tag == NovelTags.all) {
      state = {NovelTags.all};
    } else {
      final newTags = Set<String>.from(state);
      if (newTags.contains(NovelTags.all)) {
        newTags.remove(NovelTags.all);
      }
      
      if (newTags.contains(tag)) {
        newTags.remove(tag);
        if (newTags.isEmpty) {
          newTags.add(NovelTags.all);
        }
      } else {
        newTags.add(tag);
      }
      
      state = newTags;
    }
  }

  bool isSelected(String tag) {
    return state.contains(tag);
  }
} 