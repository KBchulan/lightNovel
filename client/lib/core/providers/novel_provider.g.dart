// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$apiClientHash() => r'895715fb1b3c5f39decfad436c14ff40752cfa27';

/// See also [apiClient].
@ProviderFor(apiClient)
final apiClientProvider = AutoDisposeProvider<ApiClient>.internal(
  apiClient,
  name: r'apiClientProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ApiClientRef = AutoDisposeProviderRef<ApiClient>;
String _$novelNotifierHash() => r'0722e7ddc4d216788f1fc804b30719d9644b2020';

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
String _$favoriteNotifierHash() => r'34a160f450ec0396536ae2440fe536d715267bce';

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
