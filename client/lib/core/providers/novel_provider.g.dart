// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$novelNotifierHash() => r'722181de2d0ea0cf171ad2dd658732939937f5b5';

/// See also [NovelNotifier].
@ProviderFor(NovelNotifier)
final novelNotifierProvider =
    AutoDisposeAsyncNotifierProvider<NovelNotifier, List<Novel>>.internal(
  NovelNotifier.new,
  name: r'novelNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$novelNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NovelNotifier = AutoDisposeAsyncNotifier<List<Novel>>;
String _$favoriteNotifierHash() => r'be728c42eab421c6bcfb51689914a267c4b9417c';

/// See also [FavoriteNotifier].
@ProviderFor(FavoriteNotifier)
final favoriteNotifierProvider =
    AutoDisposeAsyncNotifierProvider<FavoriteNotifier, List<Novel>>.internal(
  FavoriteNotifier.new,
  name: r'favoriteNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoriteNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FavoriteNotifier = AutoDisposeAsyncNotifier<List<Novel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
