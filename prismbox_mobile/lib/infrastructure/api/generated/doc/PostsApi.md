# prismbox_api.api.PostsApi

## Load the API package
```dart
import 'package:prismbox_api/api.dart';
```

All URIs are relative to *http://localhost:8080/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**groupsUuidFeedGet**](PostsApi.md#groupsuuidfeedget) | **GET** /groups/{uuid}/feed | 获取圈子Feed流
[**groupsUuidPostsPost**](PostsApi.md#groupsuuidpostspost) | **POST** /groups/{uuid}/posts | 创建帖子


# **groupsUuidFeedGet**
> ResponseApiResponse groupsUuidFeedGet(uuid, page, limit)

获取圈子Feed流

获取圈子的帖子Feed流，支持分页（需要认证，必须是圈子成员）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = PostsApi();
final uuid = uuid_example; // String | 圈子 UUID
final page = 56; // int | 页码（默认1）
final limit = 56; // int | 每页数量（默认20）

try {
    final result = api_instance.groupsUuidFeedGet(uuid, page, limit);
    print(result);
} catch (e) {
    print('Exception when calling PostsApi->groupsUuidFeedGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 圈子 UUID | 
 **page** | **int**| 页码（默认1） | [optional] [default to 1]
 **limit** | **int**| 每页数量（默认20） | [optional] [default to 20]

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **groupsUuidPostsPost**
> ResponseApiResponse groupsUuidPostsPost(uuid, input)

创建帖子

在圈子中创建新帖子，分享媒体（需要认证，必须是圈子成员）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = PostsApi();
final uuid = uuid_example; // String | 圈子 UUID
final input = DtoCreatePostInput(); // DtoCreatePostInput | 帖子信息

try {
    final result = api_instance.groupsUuidPostsPost(uuid, input);
    print(result);
} catch (e) {
    print('Exception when calling PostsApi->groupsUuidPostsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uuid** | **String**| 圈子 UUID | 
 **input** | [**DtoCreatePostInput**](DtoCreatePostInput.md)| 帖子信息 | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

