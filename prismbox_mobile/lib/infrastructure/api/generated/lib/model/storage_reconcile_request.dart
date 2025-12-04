//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StorageReconcileRequest {
  /// Returns a new [StorageReconcileRequest] instance.
  StorageReconcileRequest({
    this.dryRun,
    this.parallel,
    this.poolUuid,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? dryRun;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? parallel;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? poolUuid;

  @override
  bool operator ==(Object other) => identical(this, other) || other is StorageReconcileRequest &&
    other.dryRun == dryRun &&
    other.parallel == parallel &&
    other.poolUuid == poolUuid;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (dryRun == null ? 0 : dryRun!.hashCode) +
    (parallel == null ? 0 : parallel!.hashCode) +
    (poolUuid == null ? 0 : poolUuid!.hashCode);

  @override
  String toString() => 'StorageReconcileRequest[dryRun=$dryRun, parallel=$parallel, poolUuid=$poolUuid]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.dryRun != null) {
      json[r'dry_run'] = this.dryRun;
    } else {
      json[r'dry_run'] = null;
    }
    if (this.parallel != null) {
      json[r'parallel'] = this.parallel;
    } else {
      json[r'parallel'] = null;
    }
    if (this.poolUuid != null) {
      json[r'pool_uuid'] = this.poolUuid;
    } else {
      json[r'pool_uuid'] = null;
    }
    return json;
  }

  /// Returns a new [StorageReconcileRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StorageReconcileRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "StorageReconcileRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "StorageReconcileRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return StorageReconcileRequest(
        dryRun: mapValueOfType<bool>(json, r'dry_run'),
        parallel: mapValueOfType<int>(json, r'parallel'),
        poolUuid: mapValueOfType<String>(json, r'pool_uuid'),
      );
    }
    return null;
  }

  static List<StorageReconcileRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StorageReconcileRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StorageReconcileRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StorageReconcileRequest> mapFromJson(dynamic json) {
    final map = <String, StorageReconcileRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StorageReconcileRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StorageReconcileRequest-objects as value to a dart map
  static Map<String, List<StorageReconcileRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<StorageReconcileRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StorageReconcileRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

