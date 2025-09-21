// lib/flutter_replicator.dart

/// A client-side replication package designed to sync local data with a
/// changelog-based backend service.
library flutter_replicator;

// Core components
export 'src/core/replicator.dart';
export 'src/core/replicator_config.dart';

// Adapters (the contract for the app to implement)
export 'src/adapters/storage_adapter.dart';

// Public models
export 'src/models/changelog.dart';
