//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StorageCreatePoolRequest {
  /// Returns a new [StorageCreatePoolRequest] instance.
  StorageCreatePoolRequest({
    this.autoDisableThreshold,
    this.cloudConfig = const {},
    this.description,
    this.enabled,
    this.localPath,
    required this.maxSize,
    required this.name,
    this.priority,
    required this.storageType,
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

  int maxSize;

  String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? priority;

  String storageType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is StorageCreatePoolRequest &&
    other.autoDisableThreshold == autoDisableThreshold &&
    _deepEquality.equals(other.cloudConfig, cloudConfig) &&
    other.description == description &&
    other.enabled == enabled &&
    other.localPath == localPath &&
    other.maxSize == maxSize &&
    other.name == name &&
    other.priority == priority &&
    other.storageType == storageType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (autoDisableThreshold == null ? 0 : autoDisableThreshold!.hashCode) +
    (cloudConfig.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (enabled == null ? 0 : enabled!.hashCode) +
    (localPath == null ? 0 : localPath!.hashCode) +
    (maxSize.hashCode) +
    (name.hashCode) +
    (priority == null ? 0 : priority!.hashCode) +
    (storageType.hashCode);

  @override
  String toString() => 'StorageCreatePoolRequest[autoDisableThreshold=$autoDisableThreshold, cloudConfig=$cloudConfig, description=$description, enabled=$enabled, localPath=$localPath, maxSize=$maxSize, name=$name, priority=$priority, storageType=$storageType]';

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
      json[r'max_size'] = this.maxSize;
      json[r'name'] = this.name;
    if (this.priority != null) {
      json[r'priority'] = this.priority;
    } else {
      json[r'priority'] = null;
    }
      json[r'storage_type'] = this.storageType;
    return json;
  }

  /// Returns a new [StorageCreatePoolRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StorageCreatePoolRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "StorageCreatePoolRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "StorageCreatePoolRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return StorageCreatePoolRequest(
        autoDisableThreshold: num.parse('${json[r'auto_disable_threshold']}'),
        cloudConfig: mapCastOfType<String, Object>(json, r'cloud_config') ?? const {},
        description: mapValueOfType<String>(json, r'description'),
        enabled: mapValueOfType<bool>(json, r'enabled'),
        localPath: mapValueOfType<String>(json, r'local_path'),
        maxSize: mapValueOfType<int>(json, r'max_size')!,
        name: mapValueOfType<String>(json, r'name')!,
        priority: mapValueOfType<int>(json, r'priority'),
        storageType: mapValueOfType<String>(json, r'storage_type')!,
      );
    }
    return null;
  }

  static List<StorageCreatePoolRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StorageCreatePoolRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StorageCreatePoolRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StorageCreatePoolRequest> mapFromJson(dynamic json) {
    final map = <String, StorageCreatePoolRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StorageCreatePoolRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StorageCreatePoolRequest-objects as value to a dart map
  static Map<String, List<StorageCreatePoolRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<StorageCreatePoolRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StorageCreatePoolRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'max_size',
    'name',
    'storage_type',
  };
}

