# prismbox_api.api.CommentsApi

## Load the API package
```dart
import 'package:prismbox_api/api.dart';
```

All URIs are relative to *http://localhost:8080/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**commentsCommentIdDelete**](CommentsApi.md#commentscommentiddelete) | **DELETE** /comments/{commentId} | 删除评论
[**postsPostIdCommentsGet**](CommentsApi.md#postspostidcommentsget) | **GET** /posts/{postId}/comments | 获取评论列表
[**postsPostIdCommentsPost**](CommentsApi.md#postspostidcommentspost) | **POST** /posts/{postId}/comments | 添加评论


# **commentsCommentIdDelete**
> ResponseApiResponse commentsCommentIdDelete(commentId)

删除评论

删除指定的评论（需要认证，必须是评论作者或圈子管理员）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = CommentsApi();
final commentId = commentId_example; // String | 评论 ID

try {
    final result = api_instance.commentsCommentIdDelete(commentId);
    print(result);
} catch (e) {
    print('Exception when calling CommentsApi->commentsCommentIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commentId** | **String**| 评论 ID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **postsPostIdCommentsGet**
> ResponseApiResponse postsPostIdCommentsGet(postId)

获取评论列表

获取帖子的所有评论（需要认证，必须是圈子成员）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = CommentsApi();
final postId = postId_example; // String | 帖子 ID

try {
    final result = api_instance.postsPostIdCommentsGet(postId);
    print(result);
} catch (e) {
    print('Exception when calling CommentsApi->postsPostIdCommentsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **postId** | **String**| 帖子 ID | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **postsPostIdCommentsPost**
> ResponseApiResponse postsPostIdCommentsPost(postId, input)

添加评论

为帖子添加评论，支持回复其他评论（需要认证，必须是圈子成员）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = CommentsApi();
final postId = postId_example; // String | 帖子 ID
final input = DtoCreateCommentInput(); // DtoCreateCommentInput | 评论内容

try {
    final result = api_instance.postsPostIdCommentsPost(postId, input);
    print(result);
} catch (e) {
    print('Exception when calling CommentsApi->postsPostIdCommentsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **postId** | **String**| 帖子 ID | 
 **input** | [**DtoCreateCommentInput**](DtoCreateCommentInput.md)| 评论内容 | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

