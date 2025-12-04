//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class GroupsApi {
  GroupsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 获取我的圈子列表
  ///
  /// 获取当前用户加入的所有圈子列表（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> groupsGetWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/groups';

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

  /// 获取我的圈子列表
  ///
  /// 获取当前用户加入的所有圈子列表（需要认证）
  Future<ResponseApiResponse?> groupsGet() async {
    final response = await groupsGetWithHttpInfo();
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

  /// 加入圈子
  ///
  /// 使用邀请码加入圈子（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DtoJoinGroupInput] input (required):
  ///   邀请码
  Future<Response> groupsJoinPostWithHttpInfo(DtoJoinGroupInput input,) async {
    // ignore: prefer_const_declarations
    final path = r'/groups/join';

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

  /// 加入圈子
  ///
  /// 使用邀请码加入圈子（需要认证）
  ///
  /// Parameters:
  ///
  /// * [DtoJoinGroupInput] input (required):
  ///   邀请码
  Future<ResponseApiResponse?> groupsJoinPost(DtoJoinGroupInput input,) async {
    final response = await groupsJoinPostWithHttpInfo(input,);
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

  /// 创建圈子
  ///
  /// 创建一个新的圈子（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DtoCreateGroupInput] input (required):
  ///   圈子信息
  Future<Response> groupsPostWithHttpInfo(DtoCreateGroupInput input,) async {
    // ignore: prefer_const_declarations
    final path = r'/groups';

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

  /// 创建圈子
  ///
  /// 创建一个新的圈子（需要认证）
  ///
  /// Parameters:
  ///
  /// * [DtoCreateGroupInput] input (required):
  ///   圈子信息
  Future<ResponseApiResponse?> groupsPost(DtoCreateGroupInput input,) async {
    final response = await groupsPostWithHttpInfo(input,);
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

  /// 获取圈子详情
  ///
  /// 获取指定圈子的详细信息（需要认证，必须是圈子成员）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  Future<Response> groupsUuidGetWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/groups/{uuid}'
      .replaceAll('{uuid}', uuid);

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

  /// 获取圈子详情
  ///
  /// 获取指定圈子的详细信息（需要认证，必须是圈子成员）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  Future<ResponseApiResponse?> groupsUuidGet(String uuid,) async {
    final response = await groupsUuidGetWithHttpInfo(uuid,);
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

  /// 退出圈子
  ///
  /// 退出指定的圈子（需要认证，所有者不能退出）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  Future<Response> groupsUuidLeavePostWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/groups/{uuid}/leave'
      .replaceAll('{uuid}', uuid);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


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

  /// 退出圈子
  ///
  /// 退出指定的圈子（需要认证，所有者不能退出）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  Future<ResponseApiResponse?> groupsUuidLeavePost(String uuid,) async {
    final response = await groupsUuidLeavePostWithHttpInfo(uuid,);
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

  /// 获取圈子媒体预览图
  ///
  /// 获取圈子中媒体的预览图（需要认证，必须是圈子成员）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  ///
  /// * [String] mediaUuid (required):
  ///   媒体 UUID
  Future<Response> groupsUuidMediaMediaUuidPreviewGetWithHttpInfo(String uuid, String mediaUuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/groups/{uuid}/media/{media_uuid}/preview'
      .replaceAll('{uuid}', uuid)
      .replaceAll('{media_uuid}', mediaUuid);

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

  /// 获取圈子媒体预览图
  ///
  /// 获取圈子中媒体的预览图（需要认证，必须是圈子成员）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  ///
  /// * [String] mediaUuid (required):
  ///   媒体 UUID
  Future<void> groupsUuidMediaMediaUuidPreviewGet(String uuid, String mediaUuid,) async {
    final response = await groupsUuidMediaMediaUuidPreviewGetWithHttpInfo(uuid, mediaUuid,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// 获取圈子媒体缩略图
  ///
  /// 获取圈子中媒体的缩略图（需要认证，必须是圈子成员）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  ///
  /// * [String] mediaUuid (required):
  ///   媒体 UUID
  Future<Response> groupsUuidMediaMediaUuidThumbnailGetWithHttpInfo(String uuid, String mediaUuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/groups/{uuid}/media/{media_uuid}/thumbnail'
      .replaceAll('{uuid}', uuid)
      .replaceAll('{media_uuid}', mediaUuid);

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

  /// 获取圈子媒体缩略图
  ///
  /// 获取圈子中媒体的缩略图（需要认证，必须是圈子成员）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  ///
  /// * [String] mediaUuid (required):
  ///   媒体 UUID
  Future<void> groupsUuidMediaMediaUuidThumbnailGet(String uuid, String mediaUuid,) async {
    final response = await groupsUuidMediaMediaUuidThumbnailGetWithHttpInfo(uuid, mediaUuid,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// 获取圈子成员列表
  ///
  /// 获取指定圈子的所有成员列表（需要认证，必须是圈子成员）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  Future<Response> groupsUuidMembersGetWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/groups/{uuid}/members'
      .replaceAll('{uuid}', uuid);

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

  /// 获取圈子成员列表
  ///
  /// 获取指定圈子的所有成员列表（需要认证，必须是圈子成员）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  Future<ResponseApiResponse?> groupsUuidMembersGet(String uuid,) async {
    final response = await groupsUuidMembersGetWithHttpInfo(uuid,);
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

  /// 创建邀请码
  ///
  /// 为圈子创建新的邀请码（需要认证，必须是圈子管理员或所有者）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  Future<Response> groupsUuidMembersInvitePostWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/groups/{uuid}/members/invite'
      .replaceAll('{uuid}', uuid);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


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

  /// 创建邀请码
  ///
  /// 为圈子创建新的邀请码（需要认证，必须是圈子管理员或所有者）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  Future<ResponseApiResponse?> groupsUuidMembersInvitePost(String uuid,) async {
    final response = await groupsUuidMembersInvitePostWithHttpInfo(uuid,);
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

  /// 移除成员
  ///
  /// 从圈子中移除指定成员（需要认证，必须是圈子管理员或所有者，不能移除所有者）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  ///
  /// * [String] userId (required):
  ///   用户 ID
  Future<Response> groupsUuidMembersUserIdDeleteWithHttpInfo(String uuid, String userId,) async {
    // ignore: prefer_const_declarations
    final path = r'/groups/{uuid}/members/{userId}'
      .replaceAll('{uuid}', uuid)
      .replaceAll('{userId}', userId);

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

  /// 移除成员
  ///
  /// 从圈子中移除指定成员（需要认证，必须是圈子管理员或所有者，不能移除所有者）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  ///
  /// * [String] userId (required):
  ///   用户 ID
  Future<ResponseApiResponse?> groupsUuidMembersUserIdDelete(String uuid, String userId,) async {
    final response = await groupsUuidMembersUserIdDeleteWithHttpInfo(uuid, userId,);
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

  /// 更新圈子信息
  ///
  /// 更新圈子的名称和描述（需要认证，必须是圈子管理员或所有者）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  ///
  /// * [DtoUpdateGroupInput] input (required):
  ///   更新信息
  Future<Response> groupsUuidPutWithHttpInfo(String uuid, DtoUpdateGroupInput input,) async {
    // ignore: prefer_const_declarations
    final path = r'/groups/{uuid}'
      .replaceAll('{uuid}', uuid);

    // ignore: prefer_final_locals
    Object? postBody = input;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// 更新圈子信息
  ///
  /// 更新圈子的名称和描述（需要认证，必须是圈子管理员或所有者）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   圈子 UUID
  ///
  /// * [DtoUpdateGroupInput] input (required):
  ///   更新信息
  Future<ResponseApiResponse?> groupsUuidPut(String uuid, DtoUpdateGroupInput input,) async {
    final response = await groupsUuidPutWithHttpInfo(uuid, input,);
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
