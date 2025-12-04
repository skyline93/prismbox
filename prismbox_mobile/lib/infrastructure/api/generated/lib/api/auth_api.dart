//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AuthApi {
  AuthApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Apple 登录
  ///
  /// 使用 Apple ID 登录，返回访问令牌和刷新令牌
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AuthAppleLoginInput] input (required):
  ///   Apple 登录信息
  Future<Response> authAppleLoginPostWithHttpInfo(AuthAppleLoginInput input,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/apple/login';

    // ignore: prefer_final_locals
    Object? postBody = input;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Apple 登录
  ///
  /// 使用 Apple ID 登录，返回访问令牌和刷新令牌
  ///
  /// Parameters:
  ///
  /// * [AuthAppleLoginInput] input (required):
  ///   Apple 登录信息
  Future<AuthAppleLoginPost200Response?> authAppleLoginPost(AuthAppleLoginInput input,) async {
    final response = await authAppleLoginPostWithHttpInfo(input,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthAppleLoginPost200Response',) as AuthAppleLoginPost200Response;
    
    }
    return null;
  }

  /// 上传头像
  ///
  /// 上传用户头像图片（需要认证），支持 jpg、jpeg、png 格式，最大 5MB
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] avatar (required):
  ///   头像图片文件
  Future<Response> authAvatarPostWithHttpInfo(MultipartFile avatar,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/avatar';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (avatar != null) {
      hasFields = true;
      mp.fields[r'avatar'] = avatar.field;
      mp.files.add(avatar);
    }
    if (hasFields) {
      postBody = mp;
    }

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// 上传头像
  ///
  /// 上传用户头像图片（需要认证），支持 jpg、jpeg、png 格式，最大 5MB
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] avatar (required):
  ///   头像图片文件
  Future<AuthAvatarPost200Response?> authAvatarPost(MultipartFile avatar,) async {
    final response = await authAvatarPostWithHttpInfo(avatar,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthAvatarPost200Response',) as AuthAvatarPost200Response;
    
    }
    return null;
  }

  /// 用户登录
  ///
  /// 使用邮箱和密码登录，返回访问令牌和刷新令牌
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AuthLoginInput] input (required):
  ///   登录信息
  Future<Response> authLoginPostWithHttpInfo(AuthLoginInput input,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/login';

    // ignore: prefer_final_locals
    Object? postBody = input;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// 用户登录
  ///
  /// 使用邮箱和密码登录，返回访问令牌和刷新令牌
  ///
  /// Parameters:
  ///
  /// * [AuthLoginInput] input (required):
  ///   登录信息
  Future<AuthAppleLoginPost200Response?> authLoginPost(AuthLoginInput input,) async {
    final response = await authLoginPostWithHttpInfo(input,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthAppleLoginPost200Response',) as AuthAppleLoginPost200Response;
    
    }
    return null;
  }

  /// 用户登出
  ///
  /// 撤销刷新令牌，登出用户
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AuthLogoutInput] input (required):
  ///   登出信息
  Future<Response> authLogoutPostWithHttpInfo(AuthLogoutInput input,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/logout';

    // ignore: prefer_final_locals
    Object? postBody = input;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// 用户登出
  ///
  /// 撤销刷新令牌，登出用户
  ///
  /// Parameters:
  ///
  /// * [AuthLogoutInput] input (required):
  ///   登出信息
  Future<ResponseApiResponse?> authLogoutPost(AuthLogoutInput input,) async {
    final response = await authLogoutPostWithHttpInfo(input,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ResponseApiResponse',) as ResponseApiResponse;
    
    }
    return null;
  }

  /// 设置密码
  ///
  /// 为用户账号设置密码（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AuthSetPasswordInput] input (required):
  ///   密码信息
  Future<Response> authPasswordSetPostWithHttpInfo(AuthSetPasswordInput input,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/password/set';

    // ignore: prefer_final_locals
    Object? postBody = input;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// 设置密码
  ///
  /// 为用户账号设置密码（需要认证）
  ///
  /// Parameters:
  ///
  /// * [AuthSetPasswordInput] input (required):
  ///   密码信息
  Future<void> authPasswordSetPost(AuthSetPasswordInput input,) async {
    final response = await authPasswordSetPostWithHttpInfo(input,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// 获取用户资料
  ///
  /// 获取当前登录用户的资料信息（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> authProfileGetWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/auth/profile';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// 获取用户资料
  ///
  /// 获取当前登录用户的资料信息（需要认证）
  Future<ResponseApiResponse?> authProfileGet() async {
    final response = await authProfileGetWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ResponseApiResponse',) as ResponseApiResponse;
    
    }
    return null;
  }

  /// 刷新访问令牌
  ///
  /// 使用刷新令牌获取新的访问令牌
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AuthRefreshTokenInput] input (required):
  ///   刷新令牌信息
  Future<Response> authRefreshPostWithHttpInfo(AuthRefreshTokenInput input,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/refresh';

    // ignore: prefer_final_locals
    Object? postBody = input;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// 刷新访问令牌
  ///
  /// 使用刷新令牌获取新的访问令牌
  ///
  /// Parameters:
  ///
  /// * [AuthRefreshTokenInput] input (required):
  ///   刷新令牌信息
  Future<AuthRefreshPost200Response?> authRefreshPost(AuthRefreshTokenInput input,) async {
    final response = await authRefreshPostWithHttpInfo(input,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthRefreshPost200Response',) as AuthRefreshPost200Response;
    
    }
    return null;
  }

  /// 用户注册
  ///
  /// 创建新用户账号，需要提供用户名、邮箱和密码
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [InternalApiV1AuthRegisterInput] input (required):
  ///   注册信息
  Future<Response> authRegisterPostWithHttpInfo(InternalApiV1AuthRegisterInput input,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/register';

    // ignore: prefer_final_locals
    Object? postBody = input;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// 用户注册
  ///
  /// 创建新用户账号，需要提供用户名、邮箱和密码
  ///
  /// Parameters:
  ///
  /// * [InternalApiV1AuthRegisterInput] input (required):
  ///   注册信息
  Future<AuthRegisterPost200Response?> authRegisterPost(InternalApiV1AuthRegisterInput input,) async {
    final response = await authRegisterPostWithHttpInfo(input,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthRegisterPost200Response',) as AuthRegisterPost200Response;
    
    }
    return null;
  }
}
