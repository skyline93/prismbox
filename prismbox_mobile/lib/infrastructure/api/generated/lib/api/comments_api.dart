//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class CommentsApi {
  CommentsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 删除评论
  ///
  /// 删除指定的评论（需要认证，必须是评论作者或圈子管理员）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] commentId (required):
  ///   评论 ID
  Future<Response> commentsCommentIdDeleteWithHttpInfo(String commentId,) async {
    // ignore: prefer_const_declarations
    final path = r'/comments/{commentId}'
      .replaceAll('{commentId}', commentId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// 删除评论
  ///
  /// 删除指定的评论（需要认证，必须是评论作者或圈子管理员）
  ///
  /// Parameters:
  ///
  /// * [String] commentId (required):
  ///   评论 ID
  Future<ResponseApiResponse?> commentsCommentIdDelete(String commentId,) async {
    final response = await commentsCommentIdDeleteWithHttpInfo(commentId,);
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

  /// 获取评论列表
  ///
  /// 获取帖子的所有评论（需要认证，必须是圈子成员）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] postId (required):
  ///   帖子 ID
  Future<Response> postsPostIdCommentsGetWithHttpInfo(String postId,) async {
    // ignore: prefer_const_declarations
    final path = r'/posts/{postId}/comments'
      .replaceAll('{postId}', postId);

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

  /// 获取评论列表
  ///
  /// 获取帖子的所有评论（需要认证，必须是圈子成员）
  ///
  /// Parameters:
  ///
  /// * [String] postId (required):
  ///   帖子 ID
  Future<ResponseApiResponse?> postsPostIdCommentsGet(String postId,) async {
    final response = await postsPostIdCommentsGetWithHttpInfo(postId,);
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

  /// 添加评论
  ///
  /// 为帖子添加评论，支持回复其他评论（需要认证，必须是圈子成员）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] postId (required):
  ///   帖子 ID
  ///
  /// * [DtoCreateCommentInput] input (required):
  ///   评论内容
  Future<Response> postsPostIdCommentsPostWithHttpInfo(String postId, DtoCreateCommentInput input,) async {
    // ignore: prefer_const_declarations
    final path = r'/posts/{postId}/comments'
      .replaceAll('{postId}', postId);

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

  /// 添加评论
  ///
  /// 为帖子添加评论，支持回复其他评论（需要认证，必须是圈子成员）
  ///
  /// Parameters:
  ///
  /// * [String] postId (required):
  ///   帖子 ID
  ///
  /// * [DtoCreateCommentInput] input (required):
  ///   评论内容
  Future<ResponseApiResponse?> postsPostIdCommentsPost(String postId, DtoCreateCommentInput input,) async {
    final response = await postsPostIdCommentsPostWithHttpInfo(postId, input,);
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
