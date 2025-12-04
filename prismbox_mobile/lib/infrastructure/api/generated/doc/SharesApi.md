# prismbox_api.api.SharesApi

## Load the API package
```dart
import 'package:prismbox_api/api.dart';
```

All URIs are relative to *http://localhost:8080/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**sShareTokenGet**](SharesApi.md#ssharetokenget) | **GET** /s/{share_token} | 访问分享的资源
[**sharesPost**](SharesApi.md#sharespost) | **POST** /shares | 创建分享链接
[**sharesShareTokenMetaGet**](SharesApi.md#sharessharetokenmetaget) | **GET** /shares/{share_token}/meta | 获取分享元数据
[**sharesWithMeGet**](SharesApi.md#shareswithmeget) | **GET** /shares/with-me | 查看分享给我的内容


# **sShareTokenGet**
> sShareTokenGet(shareToken)

访问分享的资源

通过分享令牌访问分享的媒体资源，返回HTML页面（公开访问，不需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';

final api_instance = SharesApi();
final shareToken = shareToken_example; // String | 分享令牌

try {
    api_instance.sShareTokenGet(shareToken);
} catch (e) {
    print('Exception when calling SharesApi->sShareTokenGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shareToken** | **String**| 分享令牌 | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: text/html

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sharesPost**
> ResponseApiResponse sharesPost(input)

创建分享链接

创建媒体分享链接，可以指定目标用户或创建公开链接（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = SharesApi();
final input = DtoCreateShareInput(); // DtoCreateShareInput | 分享信息

try {
    final result = api_instance.sharesPost(input);
    print(result);
} catch (e) {
    print('Exception when calling SharesApi->sharesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **input** | [**DtoCreateShareInput**](DtoCreateShareInput.md)| 分享信息 | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sharesShareTokenMetaGet**
> ResponseApiResponse sharesShareTokenMetaGet(shareToken)

获取分享元数据

通过分享令牌获取分享的元数据信息（公开访问，不需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';

final api_instance = SharesApi();
final shareToken = shareToken_example; // String | 分享令牌

try {
    final result = api_instance.sharesShareTokenMetaGet(shareToken);
    print(result);
} catch (e) {
    print('Exception when calling SharesApi->sharesShareTokenMetaGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shareToken** | **String**| 分享令牌 | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sharesWithMeGet**
> ResponseApiResponse sharesWithMeGet()

查看分享给我的内容

获取所有分享给当前用户的内容列表（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = SharesApi();

try {
    final result = api_instance.sharesWithMeGet();
    print(result);
} catch (e) {
    print('Exception when calling SharesApi->sharesWithMeGet: $e\n');
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

