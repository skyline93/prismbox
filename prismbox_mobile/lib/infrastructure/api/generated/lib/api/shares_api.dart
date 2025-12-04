//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class SharesApi {
  SharesApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 访问分享的资源
  ///
  /// 通过分享令牌访问分享的媒体资源，返回HTML页面（公开访问，不需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shareToken (required):
  ///   分享令牌
  Future<Response> sShareTokenGetWithHttpInfo(String shareToken,) async {
    // ignore: prefer_const_declarations
    final path = r'/s/{share_token}'
      .replaceAll('{share_token}', shareToken);

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

  /// 访问分享的资源
  ///
  /// 通过分享令牌访问分享的媒体资源，返回HTML页面（公开访问，不需要认证）
  ///
  /// Parameters:
  ///
  /// * [String] shareToken (required):
  ///   分享令牌
  Future<void> sShareTokenGet(String shareToken,) async {
    final response = await sShareTokenGetWithHttpInfo(shareToken,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// 创建分享链接
  ///
  /// 创建媒体分享链接，可以指定目标用户或创建公开链接（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DtoCreateShareInput] input (required):
  ///   分享信息
  Future<Response> sharesPostWithHttpInfo(DtoCreateShareInput input,) async {
    // ignore: prefer_const_declarations
    final path = r'/shares';

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

  /// 创建分享链接
  ///
  /// 创建媒体分享链接，可以指定目标用户或创建公开链接（需要认证）
  ///
  /// Parameters:
  ///
  /// * [DtoCreateShareInput] input (required):
  ///   分享信息
  Future<ResponseApiResponse?> sharesPost(DtoCreateShareInput input,) async {
    final response = await sharesPostWithHttpInfo(input,);
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

  /// 获取分享元数据
  ///
  /// 通过分享令牌获取分享的元数据信息（公开访问，不需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] shareToken (required):
  ///   分享令牌
  Future<Response> sharesShareTokenMetaGetWithHttpInfo(String shareToken,) async {
    // ignore: prefer_const_declarations
    final path = r'/shares/{share_token}/meta'
      .replaceAll('{share_token}', shareToken);

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

  /// 获取分享元数据
  ///
  /// 通过分享令牌获取分享的元数据信息（公开访问，不需要认证）
  ///
  /// Parameters:
  ///
  /// * [String] shareToken (required):
  ///   分享令牌
  Future<ResponseApiResponse?> sharesShareTokenMetaGet(String shareToken,) async {
    final response = await sharesShareTokenMetaGetWithHttpInfo(shareToken,);
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

  /// 查看分享给我的内容
  ///
  /// 获取所有分享给当前用户的内容列表（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> sharesWithMeGetWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/shares/with-me';

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

  /// 查看分享给我的内容
  ///
  /// 获取所有分享给当前用户的内容列表（需要认证）
  Future<ResponseApiResponse?> sharesWithMeGet() async {
    final response = await sharesWithMeGetWithHttpInfo();
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
}
