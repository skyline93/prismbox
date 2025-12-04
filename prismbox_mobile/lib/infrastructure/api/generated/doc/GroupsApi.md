# prismbox_api.api.GroupsApi

## Load the API package
```dart
import 'package:prismbox_api/api.dart';
```

All URIs are relative to *http://localhost:8080/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**groupsGet**](GroupsApi.md#groupsget) | **GET** /groups | 获取我的圈子列表
[**groupsJoinPost**](GroupsApi.md#groupsjoinpost) | **POST** /groups/join | 加入圈子
[**groupsPost**](GroupsApi.md#groupspost) | **POST** /groups | 创建圈子
[**groupsUuidGet**](GroupsApi.md#groupsuuidget) | **GET** /groups/{uuid} | 获取圈子详情
[**groupsUuidLeavePost**](GroupsApi.md#groupsuuidleavepost) | **POST** /groups/{uuid}/leave | 退出圈子
[**groupsUuidMediaMediaUuidPreviewGet**](GroupsApi.md#groupsuuidmediamediauuidpreviewget) | **GET** /groups/{uuid}/media/{media_uuid}/preview | 获取圈子媒体预览图
[**groupsUuidMediaMediaUuidThumbnailGet**](GroupsApi.md#groupsuuidmediamediauuidthumbnailget) | **GET** /groups/{uuid}/media/{media_uuid}/thumbnail | 获取圈子媒体缩略图
[**groupsUuidMembersGet**](GroupsApi.md#groupsuuidmembersget) | **GET** /groups/{uuid}/members | 获取圈子成员列表
[**groupsUuidMembersInvitePost**](GroupsApi.md#groupsuuidmembersinvitepost) | **POST** /groups/{uuid}/members/invite | 创建邀请码
[**groupsUuidMembersUserIdDelete**](GroupsApi.md#groupsuuidmembersuseriddelete) | **DELETE** /groups/{uuid}/members/{userId} | 移除成员
[**groupsUuidPut**](GroupsApi.md#groupsuuidput) | **PUT** /groups/{uuid} | 更新圈子信息


# **groupsGet**
> ResponseApiResponse groupsGet()

获取我的圈子列表

获取当前用户加入的所有圈子列表（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = GroupsApi();

try {
    final result = api_instance.groupsGet();
    print(result);
} catch (e) {
    print('Exception when calling GroupsApi->groupsGet: $e\n');
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

# **groupsJoinPost**
> ResponseApiResponse groupsJoinPost(input)

加入圈子

使用邀请码加入圈子（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = GroupsApi();
final input = DtoJoinGroupInput(); // DtoJoinGroupInput | 邀请码

try {
    final result = api_instance.groupsJoinPost(input);
    print(result);
} catch (e) {
    print('Exception when calling GroupsApi->groupsJoinPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **input** | [**DtoJoinGroupInput**](DtoJoinGroupInput.md)| 邀请码 | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **groupsPost**
> ResponseApiResponse groupsPost(input)

创建圈子

创建一个新的圈子（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = GroupsApi();
final input = DtoCreateGroupInput(); // DtoCreateGroupInput | 圈子信息

try {
    final result = api_instance.groupsPost(input);
    print(result);
} catch (e) {
    print('Exception when calling GroupsApi->groupsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **input** | [**DtoCreateGroupInput**](DtoCreateGroupInput.md)| 圈子信息 | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **groupsUuidGet**
> ResponseApiResponse groupsUuidGet(uuid)

获取圈子详情

获取指定圈子的详细信息（需要认证，必须是圈子成员）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = GroupsApi();
final uuid = uuid_example; // String | 圈子 UUID

try {
    final result = api_instance.groupsUuidGet(uuid);
    print(result);
} catch (e) {
    print('Exception when calling GroupsApi->groupsUuidGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 圈子 UUID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **groupsUuidLeavePost**
> ResponseApiResponse groupsUuidLeavePost(uuid)

退出圈子

退出指定的圈子（需要认证，所有者不能退出）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = GroupsApi();
final uuid = uuid_example; // String | 圈子 UUID

try {
    final result = api_instance.groupsUuidLeavePost(uuid);
    print(result);
} catch (e) {
    print('Exception when calling GroupsApi->groupsUuidLeavePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 圈子 UUID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **groupsUuidMediaMediaUuidPreviewGet**
> groupsUuidMediaMediaUuidPreviewGet(uuid, mediaUuid)

获取圈子媒体预览图

获取圈子中媒体的预览图（需要认证，必须是圈子成员）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = GroupsApi();
final uuid = uuid_example; // String | 圈子 UUID
final mediaUuid = mediaUuid_example; // String | 媒体 UUID

try {
    api_instance.groupsUuidMediaMediaUuidPreviewGet(uuid, mediaUuid);
} catch (e) {
    print('Exception when calling GroupsApi->groupsUuidMediaMediaUuidPreviewGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 圈子 UUID | 
 **mediaUuid** | **String**| 媒体 UUID | 

### Return type

void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: image/jpeg

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **groupsUuidMediaMediaUuidThumbnailGet**
> groupsUuidMediaMediaUuidThumbnailGet(uuid, mediaUuid)

获取圈子媒体缩略图

获取圈子中媒体的缩略图（需要认证，必须是圈子成员）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = GroupsApi();
final uuid = uuid_example; // String | 圈子 UUID
final mediaUuid = mediaUuid_example; // String | 媒体 UUID

try {
    api_instance.groupsUuidMediaMediaUuidThumbnailGet(uuid, mediaUuid);
} catch (e) {
    print('Exception when calling GroupsApi->groupsUuidMediaMediaUuidThumbnailGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 圈子 UUID | 
 **mediaUuid** | **String**| 媒体 UUID | 

### Return type

void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: image/jpeg

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **groupsUuidMembersGet**
> ResponseApiResponse groupsUuidMembersGet(uuid)

获取圈子成员列表

获取指定圈子的所有成员列表（需要认证，必须是圈子成员）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = GroupsApi();
final uuid = uuid_example; // String | 圈子 UUID

try {
    final result = api_instance.groupsUuidMembersGet(uuid);
    print(result);
} catch (e) {
    print('Exception when calling GroupsApi->groupsUuidMembersGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 圈子 UUID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **groupsUuidMembersInvitePost**
> ResponseApiResponse groupsUuidMembersInvitePost(uuid)

创建邀请码

为圈子创建新的邀请码（需要认证，必须是圈子管理员或所有者）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = GroupsApi();
final uuid = uuid_example; // String | 圈子 UUID

try {
    final result = api_instance.groupsUuidMembersInvitePost(uuid);
    print(result);
} catch (e) {
    print('Exception when calling GroupsApi->groupsUuidMembersInvitePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 圈子 UUID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **groupsUuidMembersUserIdDelete**
> ResponseApiResponse groupsUuidMembersUserIdDelete(uuid, userId)

移除成员

从圈子中移除指定成员（需要认证，必须是圈子管理员或所有者，不能移除所有者）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = GroupsApi();
final uuid = uuid_example; // String | 圈子 UUID
final userId = userId_example; // String | 用户 ID

try {
    final result = api_instance.groupsUuidMembersUserIdDelete(uuid, userId);
    print(result);
} catch (e) {
    print('Exception when calling GroupsApi->groupsUuidMembersUserIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 圈子 UUID | 
 **userId** | **String**| 用户 ID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **groupsUuidPut**
> ResponseApiResponse groupsUuidPut(uuid, input)

更新圈子信息

更新圈子的名称和描述（需要认证，必须是圈子管理员或所有者）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = GroupsApi();
final uuid = uuid_example; // String | 圈子 UUID
final input = DtoUpdateGroupInput(); // DtoUpdateGroupInput | 更新信息

try {
    final result = api_instance.groupsUuidPut(uuid, input);
    print(result);
} catch (e) {
    print('Exception when calling GroupsApi->groupsUuidPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 圈子 UUID | 
 **input** | [**DtoUpdateGroupInput**](DtoUpdateGroupInput.md)| 更新信息 | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

