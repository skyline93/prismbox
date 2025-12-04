# prismbox_api.api.StorageApi

## Load the API package
```dart
import 'package:prismbox_api/api.dart';
```

All URIs are relative to *http://localhost:8080/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**storagePoolsGet**](StorageApi.md#storagepoolsget) | **GET** /storage/pools | 列出存储池
[**storagePoolsPost**](StorageApi.md#storagepoolspost) | **POST** /storage/pools | 创建存储池
[**storagePoolsReconcilePost**](StorageApi.md#storagepoolsreconcilepost) | **POST** /storage/pools/reconcile | 触发存储池对账
[**storagePoolsRefreshPost**](StorageApi.md#storagepoolsrefreshpost) | **POST** /storage/pools/refresh | 刷新存储池缓存
[**storagePoolsUsageGet**](StorageApi.md#storagepoolsusageget) | **GET** /storage/pools/usage | 获取存储池使用情况
[**storagePoolsUuidDisablePost**](StorageApi.md#storagepoolsuuiddisablepost) | **POST** /storage/pools/{uuid}/disable | 禁用存储池
[**storagePoolsUuidEnablePost**](StorageApi.md#storagepoolsuuidenablepost) | **POST** /storage/pools/{uuid}/enable | 启用存储池
[**storagePoolsUuidGet**](StorageApi.md#storagepoolsuuidget) | **GET** /storage/pools/{uuid} | 获取存储池详情
[**storagePoolsUuidPatch**](StorageApi.md#storagepoolsuuidpatch) | **PATCH** /storage/pools/{uuid} | 更新存储池


# **storagePoolsGet**
> ResponseApiResponse storagePoolsGet(storageType, status)

列出存储池

获取所有存储池列表，支持按类型和状态筛选（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = StorageApi();
final storageType = storageType_example; // String | 存储类型筛选
final status = status_example; // String | 状态筛选

try {
    final result = api_instance.storagePoolsGet(storageType, status);
    print(result);
} catch (e) {
    print('Exception when calling StorageApi->storagePoolsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **storageType** | **String**| 存储类型筛选 | [optional] 
 **status** | **String**| 状态筛选 | [optional] 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **storagePoolsPost**
> ResponseApiResponse storagePoolsPost(input)

创建存储池

创建新的存储池（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = StorageApi();
final input = StorageCreatePoolRequest(); // StorageCreatePoolRequest | 存储池信息

try {
    final result = api_instance.storagePoolsPost(input);
    print(result);
} catch (e) {
    print('Exception when calling StorageApi->storagePoolsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **input** | [**StorageCreatePoolRequest**](StorageCreatePoolRequest.md)| 存储池信息 | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **storagePoolsReconcilePost**
> ResponseApiResponse storagePoolsReconcilePost(input)

触发存储池对账

触发存储池的对账操作，检查数据库记录与实际存储的一致性（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = StorageApi();
final input = StorageReconcileRequest(); // StorageReconcileRequest | 对账参数

try {
    final result = api_instance.storagePoolsReconcilePost(input);
    print(result);
} catch (e) {
    print('Exception when calling StorageApi->storagePoolsReconcilePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **input** | [**StorageReconcileRequest**](StorageReconcileRequest.md)| 对账参数 | [optional] 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **storagePoolsRefreshPost**
> ResponseApiResponse storagePoolsRefreshPost()

刷新存储池缓存

刷新所有存储池的缓存信息（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = StorageApi();

try {
    final result = api_instance.storagePoolsRefreshPost();
    print(result);
} catch (e) {
    print('Exception when calling StorageApi->storagePoolsRefreshPost: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **storagePoolsUsageGet**
> ResponseApiResponse storagePoolsUsageGet(poolUuid)

获取存储池使用情况

获取存储池的使用情况，包括数据库记录大小和实际存储大小的对比（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = StorageApi();
final poolUuid = poolUuid_example; // String | 存储池 UUID（可选，不指定则返回所有）

try {
    final result = api_instance.storagePoolsUsageGet(poolUuid);
    print(result);
} catch (e) {
    print('Exception when calling StorageApi->storagePoolsUsageGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **poolUuid** | **String**| 存储池 UUID（可选，不指定则返回所有） | [optional] 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **storagePoolsUuidDisablePost**
> ResponseApiResponse storagePoolsUuidDisablePost(uuid)

禁用存储池

禁用指定的存储池（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = StorageApi();
final uuid = uuid_example; // String | 存储池 UUID

try {
    final result = api_instance.storagePoolsUuidDisablePost(uuid);
    print(result);
} catch (e) {
    print('Exception when calling StorageApi->storagePoolsUuidDisablePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 存储池 UUID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **storagePoolsUuidEnablePost**
> ResponseApiResponse storagePoolsUuidEnablePost(uuid)

启用存储池

启用指定的存储池（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = StorageApi();
final uuid = uuid_example; // String | 存储池 UUID

try {
    final result = api_instance.storagePoolsUuidEnablePost(uuid);
    print(result);
} catch (e) {
    print('Exception when calling StorageApi->storagePoolsUuidEnablePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 存储池 UUID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **storagePoolsUuidGet**
> ResponseApiResponse storagePoolsUuidGet(uuid)

获取存储池详情

获取指定存储池的详细信息（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = StorageApi();
final uuid = uuid_example; // String | 存储池 UUID

try {
    final result = api_instance.storagePoolsUuidGet(uuid);
    print(result);
} catch (e) {
    print('Exception when calling StorageApi->storagePoolsUuidGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 存储池 UUID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **storagePoolsUuidPatch**
> ResponseApiResponse storagePoolsUuidPatch(uuid, input)

更新存储池

更新存储池的配置信息（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = StorageApi();
final uuid = uuid_example; // String | 存储池 UUID
final input = StorageUpdatePoolRequest(); // StorageUpdatePoolRequest | 更新信息

try {
    final result = api_instance.storagePoolsUuidPatch(uuid, input);
    print(result);
} catch (e) {
    print('Exception when calling StorageApi->storagePoolsUuidPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 存储池 UUID | 
 **input** | [**StorageUpdatePoolRequest**](StorageUpdatePoolRequest.md)| 更新信息 | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

