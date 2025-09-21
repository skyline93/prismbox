// lib/src/core/replicator_config.dart

/// Holds the configuration for the Replicator instance.
class ReplicatorConfig {
  /// The base URL of the sync server API.
  ///
  /// This field is **only required** if you are NOT providing your own
  /// custom `Dio` instance to the `Replicator`. If a custom `Dio` instance
  /// is provided, its `baseUrl` will be used instead and this property
  /// will be ignored.
  ///
  /// Example: 'https://api.example.com/api/v1'
  final String? baseUrl;

  /// A unique identifier for the client device.
  /// This should persist across app restarts.
  final String deviceId;

  /// The identifier for the current user.
  final String userId;

  /// The default page size for fetching changes if not specified by the server.
  final int defaultPageLimit;

  /// Creates a configuration for the Replicator.
  const ReplicatorConfig({
    this.baseUrl,
    required this.deviceId,
    required this.userId,
    this.defaultPageLimit = 500,
  });
}
