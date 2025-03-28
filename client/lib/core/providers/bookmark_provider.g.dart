// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$novelBookmarksHash() => r'5a9a34f30fa0c707c699059d00888c7b7425de3b';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [novelBookmarks].
@ProviderFor(novelBookmarks)
const novelBookmarksProvider = NovelBookmarksFamily();

/// See also [novelBookmarks].
class NovelBookmarksFamily extends Family<AsyncValue<List<Bookmark>>> {
  /// See also [novelBookmarks].
  const NovelBookmarksFamily();

  /// See also [novelBookmarks].
  NovelBookmarksProvider call(
    String novelId,
  ) {
    return NovelBookmarksProvider(
      novelId,
    );
  }

  @override
  NovelBookmarksProvider getProviderOverride(
    covariant NovelBookmarksProvider provider,
  ) {
    return call(
      provider.novelId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'novelBookmarksProvider';
}

/// See also [novelBookmarks].
class NovelBookmarksProvider extends AutoDisposeFutureProvider<List<Bookmark>> {
  /// See also [novelBookmarks].
  NovelBookmarksProvider(
    String novelId,
  ) : this._internal(
          (ref) => novelBookmarks(
            ref as NovelBookmarksRef,
            novelId,
          ),
          from: novelBookmarksProvider,
          name: r'novelBookmarksProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$novelBookmarksHash,
          dependencies: NovelBookmarksFamily._dependencies,
          allTransitiveDependencies:
              NovelBookmarksFamily._allTransitiveDependencies,
          novelId: novelId,
        );

  NovelBookmarksProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.novelId,
  }) : super.internal();

  final String novelId;

  @override
  Override overrideWith(
    FutureOr<List<Bookmark>> Function(NovelBookmarksRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NovelBookmarksProvider._internal(
        (ref) => create(ref as NovelBookmarksRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        novelId: novelId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Bookmark>> createElement() {
    return _NovelBookmarksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NovelBookmarksProvider && other.novelId == novelId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, novelId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NovelBookmarksRef on AutoDisposeFutureProviderRef<List<Bookmark>> {
  /// The parameter `novelId` of this provider.
  String get novelId;
}

class _NovelBookmarksProviderElement
    extends AutoDisposeFutureProviderElement<List<Bookmark>>
    with NovelBookmarksRef {
  _NovelBookmarksProviderElement(super.provider);

  @override
  String get novelId => (origin as NovelBookmarksProvider).novelId;
}

String _$bookmarkNotifierHash() => r'e5d27303ad6964e17f1fa000a80f14d83062e64e';

/// See also [BookmarkNotifier].
@ProviderFor(BookmarkNotifier)
final bookmarkNotifierProvider =
    AsyncNotifierProvider<BookmarkNotifier, List<Bookmark>>.internal(
  BookmarkNotifier.new,
  name: r'bookmarkNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bookmarkNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BookmarkNotifier = AsyncNotifier<List<Bookmark>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
