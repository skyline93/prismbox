//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MediaApi {
  MediaApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 获取媒体变更
  ///
  /// 获取指定时间点之后的媒体变更记录（创建、更新、删除）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] since:
  ///   起始时间（RFC3339 格式）
  Future<Response> mediaChangesGetWithHttpInfo({ String? since, }) async {
    // ignore: prefer_const_declarations
    final path = r'/media/changes';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (since != null) {
      queryParams.addAll(_queryParams('', 'since', since));
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

  /// 获取媒体变更
  ///
  /// 获取指定时间点之后的媒体变更记录（创建、更新、删除）
  ///
  /// Parameters:
  ///
  /// * [String] since:
  ///   起始时间（RFC3339 格式）
  Future<MediaChangesGet200Response?> mediaChangesGet({ String? since, }) async {
    final response = await mediaChangesGetWithHttpInfo( since: since, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MediaChangesGet200Response',) as MediaChangesGet200Response;
    
    }
    return null;
  }

  /// 检查文件哈希
  ///
  /// 批量检查文件哈希值，返回已存在和缺失的哈希列表（用于秒传检查）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DtoCheckHashesRequest] input (required):
  ///   哈希列表
  Future<Response> mediaCheckHashesPostWithHttpInfo(DtoCheckHashesRequest input,) async {
    // ignore: prefer_const_declarations
    final path = r'/media/check_hashes';

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

  /// 检查文件哈希
  ///
  /// 批量检查文件哈希值，返回已存在和缺失的哈希列表（用于秒传检查）
  ///
  /// Parameters:
  ///
  /// * [DtoCheckHashesRequest] input (required):
  ///   哈希列表
  Future<MediaCheckHashesPost200Response?> mediaCheckHashesPost(DtoCheckHashesRequest input,) async {
    final response = await mediaCheckHashesPostWithHttpInfo(input,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MediaCheckHashesPost200Response',) as MediaCheckHashesPost200Response;
    
    }
    return null;
  }

  /// 获取媒体列表
  ///
  /// 分页获取当前用户的媒体列表，支持按类型筛选
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] page:
  ///   页码（默认1）
  ///
  /// * [int] pageSize:
  ///   每页数量（默认20，最大100）
  ///
  /// * [String] itemType:
  ///   媒体类型
  Future<Response> mediaGetWithHttpInfo({ int? page, int? pageSize, String? itemType, }) async {
    // ignore: prefer_const_declarations
    final path = r'/media';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (page != null) {
      queryParams.addAll(_queryParams('', 'page', page));
    }
    if (pageSize != null) {
      queryParams.addAll(_queryParams('', 'page_size', pageSize));
    }
    if (itemType != null) {
      queryParams.addAll(_queryParams('', 'item_type', itemType));
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

  /// 获取媒体列表
  ///
  /// 分页获取当前用户的媒体列表，支持按类型筛选
  ///
  /// Parameters:
  ///
  /// * [int] page:
  ///   页码（默认1）
  ///
  /// * [int] pageSize:
  ///   每页数量（默认20，最大100）
  ///
  /// * [String] itemType:
  ///   媒体类型
  Future<MediaGet200Response?> mediaGet({ int? page, int? pageSize, String? itemType, }) async {
    final response = await mediaGetWithHttpInfo( page: page, pageSize: pageSize, itemType: itemType, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MediaGet200Response',) as MediaGet200Response;
    
    }
    return null;
  }

  /// 上传媒体文件
  ///
  /// 上传图片或视频文件，支持秒传（通过 hash 检查）。如果文件已存在，直接返回已存在的媒体信息
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  ///   媒体文件
  ///
  /// * [String] hash (required):
  ///   文件 SHA256 哈希值（64位十六进制字符串）
  ///
  /// * [String] itemType (required):
  ///   媒体类型
  ///
  /// * [String] cloudUuid (required):
  ///   客户端生成的 UUID
  ///
  /// * [String] originalFilename:
  ///   原始文件名
  ///
  /// * [String] mediaTakenAt:
  ///   媒体拍摄时间（RFC3339 格式）
  Future<Response> mediaUploadStreamPostWithHttpInfo(MultipartFile file, String hash, String itemType, String cloudUuid, { String? originalFilename, String? mediaTakenAt, }) async {
    // ignore: prefer_const_declarations
    final path = r'/media/upload-stream';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (file != null) {
      hasFields = true;
      mp.fields[r'file'] = file.field;
      mp.files.add(file);
    }
    if (hash != null) {
      hasFields = true;
      mp.fields[r'hash'] = parameterToString(hash);
    }
    if (itemType != null) {
      hasFields = true;
      mp.fields[r'item_type'] = parameterToString(itemType);
    }
    if (cloudUuid != null) {
      hasFields = true;
      mp.fields[r'cloud_uuid'] = parameterToString(cloudUuid);
    }
    if (originalFilename != null) {
      hasFields = true;
      mp.fields[r'original_filename'] = parameterToString(originalFilename);
    }
    if (mediaTakenAt != null) {
      hasFields = true;
      mp.fields[r'media_taken_at'] = parameterToString(mediaTakenAt);
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

  /// 上传媒体文件
  ///
  /// 上传图片或视频文件，支持秒传（通过 hash 检查）。如果文件已存在，直接返回已存在的媒体信息
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  ///   媒体文件
  ///
  /// * [String] hash (required):
  ///   文件 SHA256 哈希值（64位十六进制字符串）
  ///
  /// * [String] itemType (required):
  ///   媒体类型
  ///
  /// * [String] cloudUuid (required):
  ///   客户端生成的 UUID
  ///
  /// * [String] originalFilename:
  ///   原始文件名
  ///
  /// * [String] mediaTakenAt:
  ///   媒体拍摄时间（RFC3339 格式）
  Future<MediaUuidGet200Response?> mediaUploadStreamPost(MultipartFile file, String hash, String itemType, String cloudUuid, { String? originalFilename, String? mediaTakenAt, }) async {
    final response = await mediaUploadStreamPostWithHttpInfo(file, hash, itemType, cloudUuid,  originalFilename: originalFilename, mediaTakenAt: mediaTakenAt, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MediaUuidGet200Response',) as MediaUuidGet200Response;
    
    }
    return null;
  }

  /// 删除媒体
  ///
  /// 将媒体移到回收站（软删除），可以恢复
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<Response> mediaUuidDeleteWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/media/{uuid}'
      .replaceAll('{uuid}', uuid);

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

  /// 删除媒体
  ///
  /// 将媒体移到回收站（软删除），可以恢复
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<ResponseApiResponse?> mediaUuidDelete(String uuid,) async {
    final response = await mediaUuidDeleteWithHttpInfo(uuid,);
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

  /// 下载原始文件
  ///
  /// 下载媒体的原始文件，支持认证或签名 URL 访问
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<Response> mediaUuidDownloadOriginalGetWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/media/{uuid}/download/original'
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

  /// 下载原始文件
  ///
  /// 下载媒体的原始文件，支持认证或签名 URL 访问
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<void> mediaUuidDownloadOriginalGet(String uuid,) async {
    final response = await mediaUuidDownloadOriginalGetWithHttpInfo(uuid,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// 下载预览文件
  ///
  /// 下载媒体的预览图（压缩后的图片），支持认证或签名 URL 访问
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<Response> mediaUuidDownloadPreviewGetWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/media/{uuid}/download/preview'
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

  /// 下载预览文件
  ///
  /// 下载媒体的预览图（压缩后的图片），支持认证或签名 URL 访问
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<void> mediaUuidDownloadPreviewGet(String uuid,) async {
    final response = await mediaUuidDownloadPreviewGetWithHttpInfo(uuid,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// 下载缩略图
  ///
  /// 下载媒体的缩略图（小尺寸预览），支持认证或签名 URL 访问
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<Response> mediaUuidDownloadThumbnailGetWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/media/{uuid}/download/thumbnail'
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

  /// 下载缩略图
  ///
  /// 下载媒体的缩略图（小尺寸预览），支持认证或签名 URL 访问
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<void> mediaUuidDownloadThumbnailGet(String uuid,) async {
    final response = await mediaUuidDownloadThumbnailGetWithHttpInfo(uuid,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// 获取媒体详情
  ///
  /// 获取指定媒体的详细信息，包括下载链接（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<Response> mediaUuidGetWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/media/{uuid}'
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

  /// 获取媒体详情
  ///
  /// 获取指定媒体的详细信息，包括下载链接（需要认证）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<MediaUuidGet200Response?> mediaUuidGet(String uuid,) async {
    final response = await mediaUuidGetWithHttpInfo(uuid,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MediaUuidGet200Response',) as MediaUuidGet200Response;
    
    }
    return null;
  }

  /// 永久删除媒体
  ///
  /// 永久删除媒体（硬删除），无法恢复
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<Response> mediaUuidPurgeDeleteWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/media/{uuid}/purge'
      .replaceAll('{uuid}', uuid);

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

  /// 永久删除媒体
  ///
  /// 永久删除媒体（硬删除），无法恢复
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<ResponseApiResponse?> mediaUuidPurgeDelete(String uuid,) async {
    final response = await mediaUuidPurgeDeleteWithHttpInfo(uuid,);
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

  /// 恢复媒体
  ///
  /// 从回收站恢复已删除的媒体
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<Response> mediaUuidRestorePostWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/media/{uuid}/restore'
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

  /// 恢复媒体
  ///
  /// 从回收站恢复已删除的媒体
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   媒体 UUID
  Future<ResponseApiResponse?> mediaUuidRestorePost(String uuid,) async {
    final response = await mediaUuidRestorePostWithHttpInfo(uuid,);
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
