# prismbox_api.api.MediaApi

## Load the API package
```dart
import 'package:prismbox_api/api.dart';
```

All URIs are relative to *http://localhost:8080/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**mediaChangesGet**](MediaApi.md#mediachangesget) | **GET** /media/changes | 获取媒体变更
[**mediaCheckHashesPost**](MediaApi.md#mediacheckhashespost) | **POST** /media/check_hashes | 检查文件哈希
[**mediaGet**](MediaApi.md#mediaget) | **GET** /media | 获取媒体列表
[**mediaUploadStreamPost**](MediaApi.md#mediauploadstreampost) | **POST** /media/upload-stream | 上传媒体文件
[**mediaUuidDelete**](MediaApi.md#mediauuiddelete) | **DELETE** /media/{uuid} | 删除媒体
[**mediaUuidDownloadOriginalGet**](MediaApi.md#mediauuiddownloadoriginalget) | **GET** /media/{uuid}/download/original | 下载原始文件
[**mediaUuidDownloadPreviewGet**](MediaApi.md#mediauuiddownloadpreviewget) | **GET** /media/{uuid}/download/preview | 下载预览文件
[**mediaUuidDownloadThumbnailGet**](MediaApi.md#mediauuiddownloadthumbnailget) | **GET** /media/{uuid}/download/thumbnail | 下载缩略图
[**mediaUuidGet**](MediaApi.md#mediauuidget) | **GET** /media/{uuid} | 获取媒体详情
[**mediaUuidPurgeDelete**](MediaApi.md#mediauuidpurgedelete) | **DELETE** /media/{uuid}/purge | 永久删除媒体
[**mediaUuidRestorePost**](MediaApi.md#mediauuidrestorepost) | **POST** /media/{uuid}/restore | 恢复媒体


# **mediaChangesGet**
> MediaChangesGet200Response mediaChangesGet(since)

获取媒体变更

获取指定时间点之后的媒体变更记录（创建、更新、删除）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = MediaApi();
final since = since_example; // String | 起始时间（RFC3339 格式）

try {
    final result = api_instance.mediaChangesGet(since);
    print(result);
} catch (e) {
    print('Exception when calling MediaApi->mediaChangesGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **since** | **String**| 起始时间（RFC3339 格式） | [optional] 

### Return type

[**MediaChangesGet200Response**](MediaChangesGet200Response.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaCheckHashesPost**
> MediaCheckHashesPost200Response mediaCheckHashesPost(input)

检查文件哈希

批量检查文件哈希值，返回已存在和缺失的哈希列表（用于秒传检查）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = MediaApi();
final input = DtoCheckHashesRequest(); // DtoCheckHashesRequest | 哈希列表

try {
    final result = api_instance.mediaCheckHashesPost(input);
    print(result);
} catch (e) {
    print('Exception when calling MediaApi->mediaCheckHashesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **input** | [**DtoCheckHashesRequest**](DtoCheckHashesRequest.md)| 哈希列表 | 

### Return type

[**MediaCheckHashesPost200Response**](MediaCheckHashesPost200Response.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaGet**
> MediaGet200Response mediaGet(page, pageSize, itemType)

获取媒体列表

分页获取当前用户的媒体列表，支持按类型筛选

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = MediaApi();
final page = 56; // int | 页码（默认1）
final pageSize = 56; // int | 每页数量（默认20，最大100）
final itemType = itemType_example; // String | 媒体类型

try {
    final result = api_instance.mediaGet(page, pageSize, itemType);
    print(result);
} catch (e) {
    print('Exception when calling MediaApi->mediaGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**| 页码（默认1） | [optional] [default to 1]
 **pageSize** | **int**| 每页数量（默认20，最大100） | [optional] [default to 20]
 **itemType** | **String**| 媒体类型 | [optional] 

### Return type

[**MediaGet200Response**](MediaGet200Response.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaUploadStreamPost**
> MediaUuidGet200Response mediaUploadStreamPost(file, hash, itemType, cloudUuid, originalFilename, mediaTakenAt)

上传媒体文件

上传图片或视频文件，支持秒传（通过 hash 检查）。如果文件已存在，直接返回已存在的媒体信息

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = MediaApi();
final file = BINARY_DATA_HERE; // MultipartFile | 媒体文件
final hash = hash_example; // String | 文件 SHA256 哈希值（64位十六进制字符串）
final itemType = itemType_example; // String | 媒体类型
final cloudUuid = cloudUuid_example; // String | 客户端生成的 UUID
final originalFilename = originalFilename_example; // String | 原始文件名
final mediaTakenAt = mediaTakenAt_example; // String | 媒体拍摄时间（RFC3339 格式）

try {
    final result = api_instance.mediaUploadStreamPost(file, hash, itemType, cloudUuid, originalFilename, mediaTakenAt);
    print(result);
} catch (e) {
    print('Exception when calling MediaApi->mediaUploadStreamPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**| 媒体文件 | 
 **hash** | **String**| 文件 SHA256 哈希值（64位十六进制字符串） | 
 **itemType** | **String**| 媒体类型 | 
 **cloudUuid** | **String**| 客户端生成的 UUID | 
 **originalFilename** | **String**| 原始文件名 | [optional] 
 **mediaTakenAt** | **String**| 媒体拍摄时间（RFC3339 格式） | [optional] 

### Return type

[**MediaUuidGet200Response**](MediaUuidGet200Response.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaUuidDelete**
> ResponseApiResponse mediaUuidDelete(uuid)

删除媒体

将媒体移到回收站（软删除），可以恢复

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = MediaApi();
final uuid = uuid_example; // String | 媒体 UUID

try {
    final result = api_instance.mediaUuidDelete(uuid);
    print(result);
} catch (e) {
    print('Exception when calling MediaApi->mediaUuidDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 媒体 UUID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaUuidDownloadOriginalGet**
> mediaUuidDownloadOriginalGet(uuid)

下载原始文件

下载媒体的原始文件，支持认证或签名 URL 访问

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = MediaApi();
final uuid = uuid_example; // String | 媒体 UUID

try {
    api_instance.mediaUuidDownloadOriginalGet(uuid);
} catch (e) {
    print('Exception when calling MediaApi->mediaUuidDownloadOriginalGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 媒体 UUID | 

### Return type

void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/octet-stream

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaUuidDownloadPreviewGet**
> mediaUuidDownloadPreviewGet(uuid)

下载预览文件

下载媒体的预览图（压缩后的图片），支持认证或签名 URL 访问

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = MediaApi();
final uuid = uuid_example; // String | 媒体 UUID

try {
    api_instance.mediaUuidDownloadPreviewGet(uuid);
} catch (e) {
    print('Exception when calling MediaApi->mediaUuidDownloadPreviewGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 媒体 UUID | 

### Return type

void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: image/jpeg

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaUuidDownloadThumbnailGet**
> mediaUuidDownloadThumbnailGet(uuid)

下载缩略图

下载媒体的缩略图（小尺寸预览），支持认证或签名 URL 访问

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = MediaApi();
final uuid = uuid_example; // String | 媒体 UUID

try {
    api_instance.mediaUuidDownloadThumbnailGet(uuid);
} catch (e) {
    print('Exception when calling MediaApi->mediaUuidDownloadThumbnailGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 媒体 UUID | 

### Return type

void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: image/jpeg

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaUuidGet**
> MediaUuidGet200Response mediaUuidGet(uuid)

获取媒体详情

获取指定媒体的详细信息，包括下载链接（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = MediaApi();
final uuid = uuid_example; // String | 媒体 UUID

try {
    final result = api_instance.mediaUuidGet(uuid);
    print(result);
} catch (e) {
    print('Exception when calling MediaApi->mediaUuidGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 媒体 UUID | 

### Return type

[**MediaUuidGet200Response**](MediaUuidGet200Response.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaUuidPurgeDelete**
> ResponseApiResponse mediaUuidPurgeDelete(uuid)

永久删除媒体

永久删除媒体（硬删除），无法恢复

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = MediaApi();
final uuid = uuid_example; // String | 媒体 UUID

try {
    final result = api_instance.mediaUuidPurgeDelete(uuid);
    print(result);
} catch (e) {
    print('Exception when calling MediaApi->mediaUuidPurgeDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 媒体 UUID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaUuidRestorePost**
> ResponseApiResponse mediaUuidRestorePost(uuid)

恢复媒体

从回收站恢复已删除的媒体

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = MediaApi();
final uuid = uuid_example; // String | 媒体 UUID

try {
    final result = api_instance.mediaUuidRestorePost(uuid);
    print(result);
} catch (e) {
    print('Exception when calling MediaApi->mediaUuidRestorePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 媒体 UUID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

