//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DtoCheckHashesRequest {
  /// Returns a new [DtoCheckHashesRequest] instance.
  DtoCheckHashesRequest({
    this.hashes = const [],
  });

  List<String> hashes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DtoCheckHashesRequest &&
    _deepEquality.equals(other.hashes, hashes);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (hashes.hashCode);

  @override
  String toString() => 'DtoCheckHashesRequest[hashes=$hashes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'hashes'] = this.hashes;
    return json;
  }

  /// Returns a new [DtoCheckHashesRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DtoCheckHashesRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "DtoCheckHashesRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "DtoCheckHashesRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DtoCheckHashesRequest(
        hashes: json[r'hashes'] is Iterable
            ? (json[r'hashes'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<DtoCheckHashesRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DtoCheckHashesRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DtoCheckHashesRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DtoCheckHashesRequest> mapFromJson(dynamic json) {
    final map = <String, DtoCheckHashesRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DtoCheckHashesRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DtoCheckHashesRequest-objects as value to a dart map
  static Map<String, List<DtoCheckHashesRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DtoCheckHashesRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DtoCheckHashesRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'hashes',
  };
}

