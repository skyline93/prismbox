//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AuthRefreshPost200Response {
  /// Returns a new [AuthRefreshPost200Response] instance.
  AuthRefreshPost200Response({
    this.code,
    this.data = const {},
    this.message,
  });

  /// 0=成功, 1=失败
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? code;

  Map<String, String> data;

  /// 响应消息
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? message;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthRefreshPost200Response &&
    other.code == code &&
    _deepEquality.equals(other.data, data) &&
    other.message == message;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (code == null ? 0 : code!.hashCode) +
    (data.hashCode) +
    (message == null ? 0 : message!.hashCode);

  @override
  String toString() => 'AuthRefreshPost200Response[code=$code, data=$data, message=$message]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.code != null) {
      json[r'code'] = this.code;
    } else {
      json[r'code'] = null;
    }
      json[r'data'] = this.data;
    if (this.message != null) {
      json[r'message'] = this.message;
    } else {
      json[r'message'] = null;
    }
    return json;
  }

  /// Returns a new [AuthRefreshPost200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuthRefreshPost200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AuthRefreshPost200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AuthRefreshPost200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AuthRefreshPost200Response(
        code: mapValueOfType<int>(json, r'code'),
        data: mapCastOfType<String, String>(json, r'data') ?? const {},
        message: mapValueOfType<String>(json, r'message'),
      );
    }
    return null;
  }

  static List<AuthRefreshPost200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthRefreshPost200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthRefreshPost200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuthRefreshPost200Response> mapFromJson(dynamic json) {
    final map = <String, AuthRefreshPost200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuthRefreshPost200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuthRefreshPost200Response-objects as value to a dart map
  static Map<String, List<AuthRefreshPost200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AuthRefreshPost200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuthRefreshPost200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

