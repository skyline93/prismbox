// lib/src/models/sync_response.dart

import 'changelog.dart';

/// Represents the response from the incremental sync API endpoint (`/sync`).
class IncrementalSyncResponse {
  final List<Changelog> changes;
  final int latestSeqId;
  final bool hasMore;

  IncrementalSyncResponse({
    required this.changes,
    required this.latestSeqId,
    required this.hasMore,
  });

  factory IncrementalSyncResponse.fromJson(Map<String, dynamic> json) {
    var changesList = <Changelog>[];
    if (json['changes'] != null) {
      changesList = (json['changes'] as List)
          .map((item) => Changelog.fromJson(item))
          .toList();
    }
    return IncrementalSyncResponse(
      changes: changesList,
      latestSeqId: json['latest_seq_id'] ?? 0,
      hasMore: json['has_more'] ?? false,
    );
  }
}

/// Represents the response from the full sync initialization API endpoint (`/full_init`).
class FullSyncInitResponse {
  final List<String> tablesToSync;
  final int snapshotSeqId;

  FullSyncInitResponse({
    required this.tablesToSync,
    required this.snapshotSeqId,
  });

  factory FullSyncInitResponse.fromJson(Map<String, dynamic> json) {
    return FullSyncInitResponse(
      tablesToSync: List<String>.from(json['tables_to_sync'] ?? []),
      snapshotSeqId: json['snapshot_seq_id'] ?? 0,
    );
  }
}

/// Represents the response from the full sync data fetching API endpoint (`/full_data`).
class FullSyncDataResponse {
  final List<Changelog> changes;
  final String? nextPageToken;

  FullSyncDataResponse({required this.changes, this.nextPageToken});

  factory FullSyncDataResponse.fromJson(Map<String, dynamic> json) {
    var changesList = <Changelog>[];
    if (json['changes'] != null) {
      changesList = (json['changes'] as List)
          .map((item) => Changelog.fromJson(item))
          .toList();
    }
    return FullSyncDataResponse(
      changes: changesList,
      nextPageToken: json['next_page_token'],
    );
  }
}
