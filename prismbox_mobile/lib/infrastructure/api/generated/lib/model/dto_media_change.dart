//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DtoMediaChange {
  /// Returns a new [DtoMediaChange] instance.
  DtoMediaChange({
    this.action,
    this.hash,
    this.itemType,
    this.updatedAt,
    this.uuid,
  });

  /// \"created\", \"updated\", \"deleted\"
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? action;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? hash;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? itemType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? updatedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? uuid;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DtoMediaChange &&
    other.action == action &&
    other.hash == hash &&
    other.itemType == itemType &&
    other.updatedAt == updatedAt &&
    other.uuid == uuid;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (action == null ? 0 : action!.hashCode) +
    (hash == null ? 0 : hash!.hashCode) +
    (itemType == null ? 0 : itemType!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode) +
    (uuid == null ? 0 : uuid!.hashCode);

  @override
  String toString() => 'DtoMediaChange[action=$action, hash=$hash, itemType=$itemType, updatedAt=$updatedAt, uuid=$uuid]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.action != null) {
      json[r'action'] = this.action;
    } else {
      json[r'action'] = null;
    }
    if (this.hash != null) {
      json[r'hash'] = this.hash;
    } else {
      json[r'hash'] = null;
    }
    if (this.itemType != null) {
      json[r'item_type'] = this.itemType;
    } else {
      json[r'item_type'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updated_at'] = this.updatedAt;
    } else {
      json[r'updated_at'] = null;
    }
    if (this.uuid != null) {
      json[r'uuid'] = this.uuid;
    } else {
      json[r'uuid'] = null;
    }
    return json;
  }

  /// Returns a new [DtoMediaChange] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DtoMediaChange? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "DtoMediaChange[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "DtoMediaChange[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DtoMediaChange(
        action: mapValueOfType<String>(json, r'action'),
        hash: mapValueOfType<String>(json, r'hash'),
        itemType: mapValueOfType<String>(json, r'item_type'),
        updatedAt: mapValueOfType<String>(json, r'updated_at'),
        uuid: mapValueOfType<String>(json, r'uuid'),
      );
    }
    return null;
  }

  static List<DtoMediaChange> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DtoMediaChange>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DtoMediaChange.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DtoMediaChange> mapFromJson(dynamic json) {
    final map = <String, DtoMediaChange>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DtoMediaChange.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DtoMediaChange-objects as value to a dart map
  static Map<String, List<DtoMediaChange>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DtoMediaChange>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DtoMediaChange.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

