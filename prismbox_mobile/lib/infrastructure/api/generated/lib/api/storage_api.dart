//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class StorageApi {
  StorageApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// 列出存储池
  ///
  /// 获取所有存储池列表，支持按类型和状态筛选（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] storageType:
  ///   存储类型筛选
  ///
  /// * [String] status:
  ///   状态筛选
  Future<Response> storagePoolsGetWithHttpInfo({ String? storageType, String? status, }) async {
    // ignore: prefer_const_declarations
    final path = r'/storage/pools';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (storageType != null) {
      queryParams.addAll(_queryParams('', 'storage_type', storageType));
    }
    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
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

  /// 列出存储池
  ///
  /// 获取所有存储池列表，支持按类型和状态筛选（需要认证）
  ///
  /// Parameters:
  ///
  /// * [String] storageType:
  ///   存储类型筛选
  ///
  /// * [String] status:
  ///   状态筛选
  Future<ResponseApiResponse?> storagePoolsGet({ String? storageType, String? status, }) async {
    final response = await storagePoolsGetWithHttpInfo( storageType: storageType, status: status, );
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

  /// 创建存储池
  ///
  /// 创建新的存储池（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [StorageCreatePoolRequest] input (required):
  ///   存储池信息
  Future<Response> storagePoolsPostWithHttpInfo(StorageCreatePoolRequest input,) async {
    // ignore: prefer_const_declarations
    final path = r'/storage/pools';

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

  /// 创建存储池
  ///
  /// 创建新的存储池（需要认证）
  ///
  /// Parameters:
  ///
  /// * [StorageCreatePoolRequest] input (required):
  ///   存储池信息
  Future<ResponseApiResponse?> storagePoolsPost(StorageCreatePoolRequest input,) async {
    final response = await storagePoolsPostWithHttpInfo(input,);
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

  /// 触发存储池对账
  ///
  /// 触发存储池的对账操作，检查数据库记录与实际存储的一致性（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [StorageReconcileRequest] input:
  ///   对账参数
  Future<Response> storagePoolsReconcilePostWithHttpInfo({ StorageReconcileRequest? input, }) async {
    // ignore: prefer_const_declarations
    final path = r'/storage/pools/reconcile';

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

  /// 触发存储池对账
  ///
  /// 触发存储池的对账操作，检查数据库记录与实际存储的一致性（需要认证）
  ///
  /// Parameters:
  ///
  /// * [StorageReconcileRequest] input:
  ///   对账参数
  Future<ResponseApiResponse?> storagePoolsReconcilePost({ StorageReconcileRequest? input, }) async {
    final response = await storagePoolsReconcilePostWithHttpInfo( input: input, );
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

  /// 刷新存储池缓存
  ///
  /// 刷新所有存储池的缓存信息（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> storagePoolsRefreshPostWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/storage/pools/refresh';

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

  /// 刷新存储池缓存
  ///
  /// 刷新所有存储池的缓存信息（需要认证）
  Future<ResponseApiResponse?> storagePoolsRefreshPost() async {
    final response = await storagePoolsRefreshPostWithHttpInfo();
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

  /// 获取存储池使用情况
  ///
  /// 获取存储池的使用情况，包括数据库记录大小和实际存储大小的对比（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] poolUuid:
  ///   存储池 UUID（可选，不指定则返回所有）
  Future<Response> storagePoolsUsageGetWithHttpInfo({ String? poolUuid, }) async {
    // ignore: prefer_const_declarations
    final path = r'/storage/pools/usage';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (poolUuid != null) {
      queryParams.addAll(_queryParams('', 'pool_uuid', poolUuid));
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

  /// 获取存储池使用情况
  ///
  /// 获取存储池的使用情况，包括数据库记录大小和实际存储大小的对比（需要认证）
  ///
  /// Parameters:
  ///
  /// * [String] poolUuid:
  ///   存储池 UUID（可选，不指定则返回所有）
  Future<ResponseApiResponse?> storagePoolsUsageGet({ String? poolUuid, }) async {
    final response = await storagePoolsUsageGetWithHttpInfo( poolUuid: poolUuid, );
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

  /// 禁用存储池
  ///
  /// 禁用指定的存储池（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   存储池 UUID
  Future<Response> storagePoolsUuidDisablePostWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/storage/pools/{uuid}/disable'
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

  /// 禁用存储池
  ///
  /// 禁用指定的存储池（需要认证）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   存储池 UUID
  Future<ResponseApiResponse?> storagePoolsUuidDisablePost(String uuid,) async {
    final response = await storagePoolsUuidDisablePostWithHttpInfo(uuid,);
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

  /// 启用存储池
  ///
  /// 启用指定的存储池（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   存储池 UUID
  Future<Response> storagePoolsUuidEnablePostWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/storage/pools/{uuid}/enable'
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

  /// 启用存储池
  ///
  /// 启用指定的存储池（需要认证）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   存储池 UUID
  Future<ResponseApiResponse?> storagePoolsUuidEnablePost(String uuid,) async {
    final response = await storagePoolsUuidEnablePostWithHttpInfo(uuid,);
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

  /// 获取存储池详情
  ///
  /// 获取指定存储池的详细信息（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   存储池 UUID
  Future<Response> storagePoolsUuidGetWithHttpInfo(String uuid,) async {
    // ignore: prefer_const_declarations
    final path = r'/storage/pools/{uuid}'
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

  /// 获取存储池详情
  ///
  /// 获取指定存储池的详细信息（需要认证）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   存储池 UUID
  Future<ResponseApiResponse?> storagePoolsUuidGet(String uuid,) async {
    final response = await storagePoolsUuidGetWithHttpInfo(uuid,);
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

  /// 更新存储池
  ///
  /// 更新存储池的配置信息（需要认证）
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   存储池 UUID
  ///
  /// * [StorageUpdatePoolRequest] input (required):
  ///   更新信息
  Future<Response> storagePoolsUuidPatchWithHttpInfo(String uuid, StorageUpdatePoolRequest input,) async {
    // ignore: prefer_const_declarations
    final path = r'/storage/pools/{uuid}'
      .replaceAll('{uuid}', uuid);

    // ignore: prefer_final_locals
    Object? postBody = input;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// 更新存储池
  ///
  /// 更新存储池的配置信息（需要认证）
  ///
  /// Parameters:
  ///
  /// * [String] uuid (required):
  ///   存储池 UUID
  ///
  /// * [StorageUpdatePoolRequest] input (required):
  ///   更新信息
  Future<ResponseApiResponse?> storagePoolsUuidPatch(String uuid, StorageUpdatePoolRequest input,) async {
    final response = await storagePoolsUuidPatchWithHttpInfo(uuid, input,);
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
