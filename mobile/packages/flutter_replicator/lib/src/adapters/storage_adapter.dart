// lib/src/adapters/storage_adapter.dart

import '../models/changelog.dart';

/// Enum representing the type of data modification.
/// This must align with the backend's operation types.
enum OperationType {
  /// A new record was created.
  created,

  /// An existing record was updated.
  updated,

  /// A record was deleted.
  deleted,
}

/// Abstract contract for a storage adapter.
///
/// This is the bridge between the `replicator` package and your application's
/// local database (e.g., SQLite, Hive, Isar). You must provide a concrete
/// implementation of this class that tells the replicator how to interact
/// with your data storage.
abstract class StorageAdapter {
  /// Retrieves the last successfully synced sequence ID from local storage.
  ///
  /// The replicator uses this ID to request only the changes that have occurred
  /// since the last sync. If no sync has ever occurred, this should return 0.
  Future<int> getLastSyncedSequenceId();

  /// Persists the last successfully synced sequence ID to local storage.
  ///
  /// This is called after a batch of changes has been successfully applied.
  ///
  /// [seqId] The latest sequence ID received from the server.
  Future<void> setLastSyncedSequenceId(int seqId);

  /// Prepares the local database for a full sync.
  ///
  /// This is typically used to clear out old data from tables that are about
  /// to be refilled with fresh data from the server. This should be executed
  /// in a transaction to ensure atomicity.
  ///
  /// [tables] A list of table names to be cleared, as provided by the server.
  Future<void> prepareForFullSync(List<String> tables);

  /// Applies a page of data for a specific table during a full sync.
  ///
  /// This method will be called multiple times for each table if the data is
  /// paginated. Implementations should use efficient bulk insertion methods.
  ///
  /// [tableName] The name of the table to which the data belongs.
  /// [data] A list of `Changelog` objects representing the records to be inserted.
  Future<void> applyFullSyncData(String tableName, List<Changelog> data);

  /// Applies a batch of incremental changes to the local database.
  ///
  /// This entire operation **must be atomic**. If applying any single change
  /// fails, the entire batch should be rolled back to prevent data inconsistency.
  /// Most database solutions provide a transaction mechanism for this purpose.
  ///
  /// [changes] A list of `Changelog` objects to be applied.
  Future<void> applyIncrementalChanges(List<Changelog> changes);
}
