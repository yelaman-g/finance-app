// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$momentsRepositoryHash() => r'ddaf5f3f1048326a978d516b896f698797f1f675';

/// See also [momentsRepository].
@ProviderFor(momentsRepository)
final momentsRepositoryProvider =
    AutoDisposeProvider<MomentsRepositoryImpl>.internal(
  momentsRepository,
  name: r'momentsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$momentsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MomentsRepositoryRef = AutoDisposeProviderRef<MomentsRepositoryImpl>;
String _$storiesHash() => r'06eadc2a11754e12eea2909923e9a6a7b48ae6e4';

/// See also [stories].
@ProviderFor(stories)
final storiesProvider = AutoDisposeFutureProvider<List<Moment>>.internal(
  stories,
  name: r'storiesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$storiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StoriesRef = AutoDisposeFutureProviderRef<List<Moment>>;
String _$momentsFeedNotifierHash() =>
    r'0df68984e992f9fe93b8e560628e46f4c097f6d4';

/// See also [MomentsFeedNotifier].
@ProviderFor(MomentsFeedNotifier)
final momentsFeedNotifierProvider = AutoDisposeAsyncNotifierProvider<
    MomentsFeedNotifier, List<Moment>>.internal(
  MomentsFeedNotifier.new,
  name: r'momentsFeedNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$momentsFeedNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MomentsFeedNotifier = AutoDisposeAsyncNotifier<List<Moment>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
