// lib/src/models/changelog.dart

import '../adapters/storage_adapter.dart';

/// Represents a single data change record from the server's changelog.
class Changelog {
  /// A unique, auto-incrementing ID for the change.
  final int sequenceId;

  /// The name of the table where the change occurred.
  final String tableName;

  /// The unique identifier of the record that was changed.
  final String recordId;

  /// The type of operation (CREATED, UPDATED, DELETED).
  final OperationType operationType;

  /// The JSON payload of the record after the change.
  /// This will be `null` for DELETED operations.
  final Map<String, dynamic>? payload;

  /// The UTC timestamp of when the change occurred.
  final DateTime timestamp;

  Changelog({
    required this.sequenceId,
    required this.tableName,
    required this.recordId,
    required this.operationType,
    this.payload,
    required this.timestamp,
  });

  /// Creates a [Changelog] instance from a JSON map.
  factory Changelog.fromJson(Map<String, dynamic> json) {
    // Backend may use snake_case or PascalCase, handle both.
    final sequence = json['sequence_id'] ?? json['SequenceID'] ?? 0;
    final table = json['table_name'] ?? json['TableName'] ?? '';
    final record = json['record_id'] ?? json['RecordID'] ?? '';
    final opType = json['operation_type'] ?? json['OperationType'];
    final time = json['timestamp'] ?? json['Timestamp'];

    return Changelog(
      sequenceId: sequence is int
          ? sequence
          : int.tryParse(sequence.toString()) ?? 0,
      tableName: table,
      recordId: record,
      operationType: _parseOperationType(opType),
      payload: json['Payload'] != null
          ? Map<String, dynamic>.from(json['Payload'])
          : null,
      timestamp: DateTime.parse(time ?? DateTime.now().toIso8601String()),
    );
  }

  /// Helper to parse the operation type string into an enum.
  static OperationType _parseOperationType(String? type) {
    switch (type) {
      case 'CREATED':
        return OperationType.created;
      case 'UPDATED':
        return OperationType.updated;
      case 'DELETED':
        return OperationType.deleted;
      default:
        // Default to a safe value to prevent accidental data loss.
        // If an unknown operation is received, treating it as an update is often safest.
        return OperationType.updated;
    }
  }

  @override
  String toString() {
    return 'Changelog(seqId: $sequenceId, table: $tableName, recordId: $recordId, op: $operationType)';
  }
}
