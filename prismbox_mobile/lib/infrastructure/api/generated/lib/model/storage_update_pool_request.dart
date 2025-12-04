//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StorageUpdatePoolRequest {
  /// Returns a new [StorageUpdatePoolRequest] instance.
  StorageUpdatePoolRequest({
    this.autoDisableThreshold,
    this.cloudConfig = const {},
    this.description,
    this.enabled,
    this.localPath,
    this.maxSize,
    this.name,
    this.priority,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? autoDisableThreshold;

  Map<String, Object> cloudConfig;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? enabled;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? localPath;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? maxSize;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? priority;

  @override
  bool operator ==(Object other) => identical(this, other) || other is StorageUpdatePoolRequest &&
    other.autoDisableThreshold == autoDisableThreshold &&
    _deepEquality.equals(other.cloudConfig, cloudConfig) &&
    other.description == description &&
    other.enabled == enabled &&
    other.localPath == localPath &&
    other.maxSize == maxSize &&
    other.name == name &&
    other.priority == priority;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (autoDisableThreshold == null ? 0 : autoDisableThreshold!.hashCode) +
    (cloudConfig.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (enabled == null ? 0 : enabled!.hashCode) +
    (localPath == null ? 0 : localPath!.hashCode) +
    (maxSize == null ? 0 : maxSize!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (priority == null ? 0 : priority!.hashCode);

  @override
  String toString() => 'StorageUpdatePoolRequest[autoDisableThreshold=$autoDisableThreshold, cloudConfig=$cloudConfig, description=$description, enabled=$enabled, localPath=$localPath, maxSize=$maxSize, name=$name, priority=$priority]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.autoDisableThreshold != null) {
      json[r'auto_disable_threshold'] = this.autoDisableThreshold;
    } else {
      json[r'auto_disable_threshold'] = null;
    }
      json[r'cloud_config'] = this.cloudConfig;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.enabled != null) {
      json[r'enabled'] = this.enabled;
    } else {
      json[r'enabled'] = null;
    }
    if (this.localPath != null) {
      json[r'local_path'] = this.localPath;
    } else {
      json[r'local_path'] = null;
    }
    if (this.maxSize != null) {
      json[r'max_size'] = this.maxSize;
    } else {
      json[r'max_size'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.priority != null) {
      json[r'priority'] = this.priority;
    } else {
      json[r'priority'] = null;
    }
    return json;
  }

  /// Returns a new [StorageUpdatePoolRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StorageUpdatePoolRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "StorageUpdatePoolRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "StorageUpdatePoolRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return StorageUpdatePoolRequest(
        autoDisableThreshold: num.parse('${json[r'auto_disable_threshold']}'),
        cloudConfig: mapCastOfType<String, Object>(json, r'cloud_config') ?? const {},
        description: mapValueOfType<String>(json, r'description'),
        enabled: mapValueOfType<bool>(json, r'enabled'),
        localPath: mapValueOfType<String>(json, r'local_path'),
        maxSize: mapValueOfType<int>(json, r'max_size'),
        name: mapValueOfType<String>(json, r'name'),
        priority: mapValueOfType<int>(json, r'priority'),
      );
    }
    return null;
  }

  static List<StorageUpdatePoolRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StorageUpdatePoolRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StorageUpdatePoolRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StorageUpdatePoolRequest> mapFromJson(dynamic json) {
    final map = <String, StorageUpdatePoolRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StorageUpdatePoolRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StorageUpdatePoolRequest-objects as value to a dart map
  static Map<String, List<StorageUpdatePoolRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<StorageUpdatePoolRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StorageUpdatePoolRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

