// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chapterNotifierHash() => r'ea0b25466be227ce50a68eb1ffb6154b8f6ea749';

/// 章节目录状态
///
/// Copied from [ChapterNotifier].
@ProviderFor(ChapterNotifier)
final chapterNotifierProvider = AutoDisposeNotifierProvider<ChapterNotifier,
    Map<int, List<ChapterInfo>>>.internal(
  ChapterNotifier.new,
  name: r'chapterNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chapterNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChapterNotifier = AutoDisposeNotifier<Map<int, List<ChapterInfo>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
