//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library openapi.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/auth_api.dart';
part 'api/comments_api.dart';
part 'api/discovery_api.dart';
part 'api/groups_api.dart';
part 'api/media_api.dart';
part 'api/posts_api.dart';
part 'api/server_api.dart';
part 'api/shares_api.dart';
part 'api/storage_api.dart';

part 'model/auth_apple_login_input.dart';
part 'model/auth_apple_login_input_full_name.dart';
part 'model/auth_apple_login_post200_response.dart';
part 'model/auth_avatar_post200_response.dart';
part 'model/auth_login_input.dart';
part 'model/auth_login_success_data.dart';
part 'model/auth_logout_input.dart';
part 'model/auth_refresh_post200_response.dart';
part 'model/auth_refresh_token_input.dart';
part 'model/auth_register_post200_response.dart';
part 'model/auth_register_success_data.dart';
part 'model/auth_set_password_input.dart';
part 'model/auth_upload_avatar_success_data.dart';
part 'model/dto_check_hashes_request.dart';
part 'model/dto_check_hashes_response.dart';
part 'model/dto_create_comment_input.dart';
part 'model/dto_create_group_input.dart';
part 'model/dto_create_post_input.dart';
part 'model/dto_create_share_input.dart';
part 'model/dto_get_changes_response.dart';
part 'model/dto_get_medias_response.dart';
part 'model/dto_join_group_input.dart';
part 'model/dto_media_change.dart';
part 'model/dto_media_response.dart';
part 'model/dto_update_group_input.dart';
part 'model/internal_api_v1_auth_register_input.dart';
part 'model/media_changes_get200_response.dart';
part 'model/media_check_hashes_post200_response.dart';
part 'model/media_get200_response.dart';
part 'model/media_uuid_get200_response.dart';
part 'model/response_api_response.dart';
part 'model/storage_create_pool_request.dart';
part 'model/storage_reconcile_request.dart';
part 'model/storage_update_pool_request.dart';


/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) => pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
