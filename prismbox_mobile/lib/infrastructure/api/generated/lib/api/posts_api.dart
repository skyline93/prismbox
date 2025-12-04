//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class PostsApi {
  PostsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 获取圈子Feed流
  ///
  /// 获取圈子的帖子Feed流，支持分页（需要认证，必须是圈子成员）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  ///
  /// * [int] page:
  ///   页码（默认1）
  ///
  /// * [int] limit:
  ///   每页数量（默认20）
  Future<Response> groupsUuidFeedGetWithHttpInfo(String uuid, { int? page, int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/groups/{uuid}/feed'
      .replaceAll('{uuid}', uuid);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (page != null) {
      queryParams.addAll(_queryParams('', 'page', page));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }

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

  /// 获取圈子Feed流
  ///
  /// 获取圈子的帖子Feed流，支持分页（需要认证，必须是圈子成员）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  ///
  /// * [int] page:
  ///   页码（默认1）
  ///
  /// * [int] limit:
  ///   每页数量（默认20）
  Future<ResponseApiResponse?> groupsUuidFeedGet(String uuid, { int? page, int? limit, }) async {
    final response = await groupsUuidFeedGetWithHttpInfo(uuid,  page: page, limit: limit, );
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

  /// 创建帖子
  ///
  /// 在圈子中创建新帖子，分享媒体（需要认证，必须是圈子成员）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  ///
  /// * [DtoCreatePostInput] input (required):
  ///   帖子信息
  Future<Response> groupsUuidPostsPostWithHttpInfo(String uuid, DtoCreatePostInput input,) async {
    // ignore: prefer_const_declarations
    final path = r'/groups/{uuid}/posts'
      .replaceAll('{uuid}', uuid);

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

  /// 创建帖子
  ///
  /// 在圈子中创建新帖子，分享媒体（需要认证，必须是圈子成员）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  ///
  /// * [DtoCreatePostInput] input (required):
  ///   帖子信息
  Future<ResponseApiResponse?> groupsUuidPostsPost(String uuid, DtoCreatePostInput input,) async {
    final response = await groupsUuidPostsPostWithHttpInfo(uuid, input,);
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
