//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DtoCheckHashesResponse {
  /// Returns a new [DtoCheckHashesResponse] instance.
  DtoCheckHashesResponse({
    this.existingHashes = const [],
    this.missingHashes = const [],
  });

  List<String> existingHashes;

  List<String> missingHashes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DtoCheckHashesResponse &&
    _deepEquality.equals(other.existingHashes, existingHashes) &&
    _deepEquality.equals(other.missingHashes, missingHashes);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (existingHashes.hashCode) +
    (missingHashes.hashCode);

  @override
  String toString() => 'DtoCheckHashesResponse[existingHashes=$existingHashes, missingHashes=$missingHashes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'existing_hashes'] = this.existingHashes;
      json[r'missing_hashes'] = this.missingHashes;
    return json;
  }

  /// Returns a new [DtoCheckHashesResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DtoCheckHashesResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "DtoCheckHashesResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "DtoCheckHashesResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DtoCheckHashesResponse(
        existingHashes: json[r'existing_hashes'] is Iterable
            ? (json[r'existing_hashes'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        missingHashes: json[r'missing_hashes'] is Iterable
            ? (json[r'missing_hashes'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<DtoCheckHashesResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DtoCheckHashesResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DtoCheckHashesResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DtoCheckHashesResponse> mapFromJson(dynamic json) {
    final map = <String, DtoCheckHashesResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DtoCheckHashesResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DtoCheckHashesResponse-objects as value to a dart map
  static Map<String, List<DtoCheckHashesResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DtoCheckHashesResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DtoCheckHashesResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

