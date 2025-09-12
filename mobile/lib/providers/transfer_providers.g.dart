// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transferManagerHash() => r'597fa1cea5b5cb233c83189371882b8c4bd5d897';

/// See also [transferManager].
@ProviderFor(transferManager)
final transferManagerProvider = Provider<TransferManager>.internal(
  transferManager,
  name: r'transferManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transferManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TransferManagerRef = ProviderRef<TransferManager>;
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

typedef UploadJobsRef = AutoDisposeStreamProviderRef<List<UploadJob>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
