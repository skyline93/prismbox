// lib/src/core/replicator.dart

import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../adapters/storage_adapter.dart';
import '../services/api_client.dart';
import 'replicator_config.dart';

/// The main orchestrator for the data synchronization process.
///
/// `Replicator` coordinates communication between the `ApiClient` (network)
/// and the `StorageAdapter` (local database) to perform both full and
/// incremental data syncs.
class Replicator {
  /// Configuration for the replicator.
  final ReplicatorConfig config;

  /// The storage adapter that connects to the local database.
  final StorageAdapter storage;

  /// The client for making API calls to the backend.
  final ApiClient apiClient;

  // A simple lock to prevent multiple sync operations from running concurrently.
  bool _isSyncing = false;

  /// Creates a new `Replicator` instance.
  ///
  /// Requires a [config] object with connection details and a [storage]
  /// adapter implementation for handling local data persistence.
  ///
  /// An optional [dio] instance can be provided to use an existing,
  /// pre-configured network client. If not provided, a default one
  /// will be created.
  Replicator({
    required this.config,
    required this.storage,
    Dio? dio,
  }) : apiClient = ApiClient(config: config, dio: dio);

  /// Initiates the synchronization process.
  ///
  /// This is the primary public method to start syncing. It automatically
  /// determines whether to perform a full sync (for new clients) or an
  /// incremental sync based on the `lastSyncedSequenceId` from the [storage] adapter.
  ///
  /// If a sync is already in progress, this method will do nothing.
  Future<void> sync() async {
    if (_isSyncing) {
      log('Sync already in progress. Skipping.', name: 'Replicator');
      return;
    }
    _isSyncing = true;
    log('Sync started.', name: 'Replicator');

    try {
      final lastSeqId = await storage.getLastSyncedSequenceId();
      if (lastSeqId == 0) {
        log(
          'No previous sync state found. Starting full sync.',
          name: 'Replicator',
        );
        await _runFullSync();
      }
      // Always run incremental sync after a full sync to catch up on any
      // changes that occurred during the full sync process.
      await _runIncrementalSync();
    } catch (e, stacktrace) {
      log(
        'Sync failed with error: $e',
        stackTrace: stacktrace,
        name: 'Replicator',
        error: e,
      );
      // Depending on the app's requirements, you might want to re-throw the error
      // so the UI can be notified.
      rethrow;
    } finally {
      _isSyncing = false;
      log('Sync finished.', name: 'Replicator');
    }
  }

  /// Executes the full sync process.
  Future<void> _runFullSync() async {
    log('Running full sync...', name: 'Replicator');

    // 1. Get the list of tables and the snapshot sequence ID from the server.
    final initData = await apiClient.fetchFullSyncInit();
    final tablesToSync = initData.tablesToSync;
    final snapshotSeqId = initData.snapshotSeqId;

    if (tablesToSync.isEmpty) {
      log(
        'No tables configured for full sync. Aborting full sync.',
        name: 'Replicator',
      );
      return;
    }
    log(
      'Tables to sync: $tablesToSync. Snapshot sequence ID: $snapshotSeqId',
      name: 'Replicator',
    );

    // 2. Instruct the storage adapter to prepare for the full sync (e.g., clear tables).
    await storage.prepareForFullSync(tablesToSync);

    // 3. Fetch and apply data for each table page by page.
    for (final tableName in tablesToSync) {
      String? pageToken;
      do {
        log(
          'Fetching data for table: $tableName, pageToken: $pageToken',
          name: 'Replicator',
        );
        final dataResponse = await apiClient.fetchFullSyncData(
          tableName,
          pageToken,
        );

        if (dataResponse.changes.isNotEmpty) {
          await storage.applyFullSyncData(tableName, dataResponse.changes);
          log(
            'Applied ${dataResponse.changes.length} records to table $tableName.',
            name: 'Replicator',
          );
        }

        pageToken = dataResponse.nextPageToken;
      } while (pageToken != null && pageToken.isNotEmpty);
    }

    // 4. Once all data is successfully downloaded and applied, set the sequence ID.
    await storage.setLastSyncedSequenceId(snapshotSeqId);
    log(
      'Full sync complete. Initial sequence ID set to: $snapshotSeqId',
      name: 'Replicator',
    );
  }

  /// Executes the incremental sync process.
  Future<void> _runIncrementalSync() async {
    log('Running incremental sync...', name: 'Replicator');
    bool hasMore = true;

    while (hasMore) {
      final lastSeqId = await storage.getLastSyncedSequenceId();
      log('Fetching changes after sequence ID: $lastSeqId', name: 'Replicator');

      final response = await apiClient.fetchIncrementalChanges(lastSeqId);

      if (response.changes.isNotEmpty) {
        // The storage adapter MUST implement this atomically.
        await storage.applyIncrementalChanges(response.changes);
        await storage.setLastSyncedSequenceId(response.latestSeqId);
        log(
          'Applied ${response.changes.length} changes. New sequence ID: ${response.latestSeqId}',
          name: 'Replicator',
        );
      } else {
        log('No new changes found.', name: 'Replicator');
      }

      hasMore = response.hasMore;
    }
    log('Incremental sync complete.', name: 'Replicator');
  }
}
