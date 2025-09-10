// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transferServiceHash() => r'74604e7f8ea9b69620c634262e27e2942ead5874';

/// See also [transferService].
@ProviderFor(transferService)
final transferServiceProvider = Provider<TransferService>.internal(
  transferService,
  name: r'transferServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transferServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TransferServiceRef = ProviderRef<TransferService>;
String _$downloadJobDaoHash() => r'87983842dfc4ab2e48c77fb6e54237e2cb44ab47';

/// See also [downloadJobDao].
@ProviderFor(downloadJobDao)
final downloadJobDaoProvider = AutoDisposeProvider<DownloadJobDao>.internal(
  downloadJobDao,
  name: r'downloadJobDaoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$downloadJobDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DownloadJobDaoRef = AutoDisposeProviderRef<DownloadJobDao>;
String _$downloadJobsHash() => r'2080292b2012261d3fc9b1643e72cc2862afe849';

/// See also [downloadJobs].
@ProviderFor(downloadJobs)
final downloadJobsProvider =
    AutoDisposeStreamProvider<List<DownloadJob>>.internal(
  downloadJobs,
  name: r'downloadJobsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$downloadJobsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DownloadJobsRef = AutoDisposeStreamProviderRef<List<DownloadJob>>;
String _$uploadJobDaoHash() => r'51912cfdfb546b1c1e67e701ba0cd95225df5951';

/// See also [uploadJobDao].
@ProviderFor(uploadJobDao)
final uploadJobDaoProvider = AutoDisposeProvider<UploadJobDao>.internal(
  uploadJobDao,
  name: r'uploadJobDaoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$uploadJobDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UploadJobDaoRef = AutoDisposeProviderRef<UploadJobDao>;
String _$uploadJobsHash() => r'1439e7b484b30b1f38062c5580abd2ca5bb7a5ce';

/// See also [uploadJobs].
@ProviderFor(uploadJobs)
final uploadJobsProvider = AutoDisposeStreamProvider<List<UploadJob>>.internal(
  uploadJobs,
  name: r'uploadJobsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$uploadJobsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UploadJobsRef = AutoDisposeStreamProviderRef<List<UploadJob>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
