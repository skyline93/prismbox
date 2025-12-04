//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AuthAppleLoginInput {
  /// Returns a new [AuthAppleLoginInput] instance.
  AuthAppleLoginInput({
    this.fullName,
    required this.identityToken,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  AuthAppleLoginInputFullName? fullName;

  String identityToken;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthAppleLoginInput &&
    other.fullName == fullName &&
    other.identityToken == identityToken;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fullName == null ? 0 : fullName!.hashCode) +
    (identityToken.hashCode);

  @override
  String toString() => 'AuthAppleLoginInput[fullName=$fullName, identityToken=$identityToken]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.fullName != null) {
      json[r'fullName'] = this.fullName;
    } else {
      json[r'fullName'] = null;
    }
      json[r'identityToken'] = this.identityToken;
    return json;
  }

  /// Returns a new [AuthAppleLoginInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuthAppleLoginInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AuthAppleLoginInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AuthAppleLoginInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AuthAppleLoginInput(
        fullName: AuthAppleLoginInputFullName.fromJson(json[r'fullName']),
        identityToken: mapValueOfType<String>(json, r'identityToken')!,
      );
    }
    return null;
  }

  static List<AuthAppleLoginInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthAppleLoginInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthAppleLoginInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuthAppleLoginInput> mapFromJson(dynamic json) {
    final map = <String, AuthAppleLoginInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuthAppleLoginInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuthAppleLoginInput-objects as value to a dart map
  static Map<String, List<AuthAppleLoginInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AuthAppleLoginInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuthAppleLoginInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'identityToken',
  };
}

