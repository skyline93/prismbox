//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InternalApiV1AuthRegisterInput {
  /// Returns a new [InternalApiV1AuthRegisterInput] instance.
  InternalApiV1AuthRegisterInput({
    required this.email,
    required this.password,
    required this.username,
  });

  /// 邮箱地址
  String email;

  /// 密码（至少8位）
  String password;

  /// 用户名
  String username;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InternalApiV1AuthRegisterInput &&
    other.email == email &&
    other.password == password &&
    other.username == username;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email.hashCode) +
    (password.hashCode) +
    (username.hashCode);

  @override
  String toString() => 'InternalApiV1AuthRegisterInput[email=$email, password=$password, username=$username]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email'] = this.email;
      json[r'password'] = this.password;
      json[r'username'] = this.username;
    return json;
  }

  /// Returns a new [InternalApiV1AuthRegisterInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InternalApiV1AuthRegisterInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "InternalApiV1AuthRegisterInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "InternalApiV1AuthRegisterInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return InternalApiV1AuthRegisterInput(
        email: mapValueOfType<String>(json, r'email')!,
        password: mapValueOfType<String>(json, r'password')!,
        username: mapValueOfType<String>(json, r'username')!,
      );
    }
    return null;
  }

  static List<InternalApiV1AuthRegisterInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InternalApiV1AuthRegisterInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InternalApiV1AuthRegisterInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InternalApiV1AuthRegisterInput> mapFromJson(dynamic json) {
    final map = <String, InternalApiV1AuthRegisterInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InternalApiV1AuthRegisterInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InternalApiV1AuthRegisterInput-objects as value to a dart map
  static Map<String, List<InternalApiV1AuthRegisterInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InternalApiV1AuthRegisterInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InternalApiV1AuthRegisterInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
    'password',
    'username',
  };
}

