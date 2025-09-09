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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
