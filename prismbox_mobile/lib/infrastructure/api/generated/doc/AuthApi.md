# prismbox_api.api.AuthApi

## Load the API package
```dart
import 'package:prismbox_api/api.dart';
```

All URIs are relative to *http://localhost:8080/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authAppleLoginPost**](AuthApi.md#authappleloginpost) | **POST** /auth/apple/login | Apple 登录
[**authAvatarPost**](AuthApi.md#authavatarpost) | **POST** /auth/avatar | 上传头像
[**authLoginPost**](AuthApi.md#authloginpost) | **POST** /auth/login | 用户登录
[**authLogoutPost**](AuthApi.md#authlogoutpost) | **POST** /auth/logout | 用户登出
[**authPasswordSetPost**](AuthApi.md#authpasswordsetpost) | **POST** /auth/password/set | 设置密码
[**authProfileGet**](AuthApi.md#authprofileget) | **GET** /auth/profile | 获取用户资料
[**authRefreshPost**](AuthApi.md#authrefreshpost) | **POST** /auth/refresh | 刷新访问令牌
[**authRegisterPost**](AuthApi.md#authregisterpost) | **POST** /auth/register | 用户注册


# **authAppleLoginPost**
> AuthAppleLoginPost200Response authAppleLoginPost(input)

Apple 登录

使用 Apple ID 登录，返回访问令牌和刷新令牌

### Example
```dart
import 'package:prismbox_api/api.dart';

final api_instance = AuthApi();
final input = AuthAppleLoginInput(); // AuthAppleLoginInput | Apple 登录信息

try {
    final result = api_instance.authAppleLoginPost(input);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->authAppleLoginPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **input** | [**AuthAppleLoginInput**](AuthAppleLoginInput.md)| Apple 登录信息 | 

### Return type

[**AuthAppleLoginPost200Response**](AuthAppleLoginPost200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authAvatarPost**
> AuthAvatarPost200Response authAvatarPost(avatar)

上传头像

上传用户头像图片（需要认证），支持 jpg、jpeg、png 格式，最大 5MB

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = AuthApi();
final avatar = BINARY_DATA_HERE; // MultipartFile | 头像图片文件

try {
    final result = api_instance.authAvatarPost(avatar);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->authAvatarPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **avatar** | **MultipartFile**| 头像图片文件 | 

### Return type

[**AuthAvatarPost200Response**](AuthAvatarPost200Response.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authLoginPost**
> AuthAppleLoginPost200Response authLoginPost(input)

用户登录

使用邮箱和密码登录，返回访问令牌和刷新令牌

### Example
```dart
import 'package:prismbox_api/api.dart';

final api_instance = AuthApi();
final input = AuthLoginInput(); // AuthLoginInput | 登录信息

try {
    final result = api_instance.authLoginPost(input);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->authLoginPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **input** | [**AuthLoginInput**](AuthLoginInput.md)| 登录信息 | 

### Return type

[**AuthAppleLoginPost200Response**](AuthAppleLoginPost200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authLogoutPost**
> ResponseApiResponse authLogoutPost(input)

用户登出

撤销刷新令牌，登出用户

### Example
```dart
import 'package:prismbox_api/api.dart';

final api_instance = AuthApi();
final input = AuthLogoutInput(); // AuthLogoutInput | 登出信息

try {
    final result = api_instance.authLogoutPost(input);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->authLogoutPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **input** | [**AuthLogoutInput**](AuthLogoutInput.md)| 登出信息 | 

### Return type

[**ResponseApiResponse**](ResponseApiResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authPasswordSetPost**
> authPasswordSetPost(input)

设置密码

为用户账号设置密码（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = AuthApi();
final input = AuthSetPasswordInput(); // AuthSetPasswordInput | 密码信息

try {
    api_instance.authPasswordSetPost(input);
} catch (e) {
    print('Exception when calling AuthApi->authPasswordSetPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **input** | [**AuthSetPasswordInput**](AuthSetPasswordInput.md)| 密码信息 | 

### Return type

void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authProfileGet**
> ResponseApiResponse authProfileGet()

获取用户资料

获取当前登录用户的资料信息（需要认证）

### Example
```dart
import 'package:prismbox_api/api.dart';
// TODO Configure API key authorization: BearerAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('BearerAuth').apiKeyPrefix = 'Bearer';

final api_instance = AuthApi();

try {
    final result = api_instance.authProfileGet();
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->authProfileGet: $e\n');
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

# **authRefreshPost**
> AuthRefreshPost200Response authRefreshPost(input)

刷新访问令牌

使用刷新令牌获取新的访问令牌

### Example
```dart
import 'package:prismbox_api/api.dart';

final api_instance = AuthApi();
final input = AuthRefreshTokenInput(); // AuthRefreshTokenInput | 刷新令牌信息

try {
    final result = api_instance.authRefreshPost(input);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->authRefreshPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **input** | [**AuthRefreshTokenInput**](AuthRefreshTokenInput.md)| 刷新令牌信息 | 

### Return type

[**AuthRefreshPost200Response**](AuthRefreshPost200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authRegisterPost**
> AuthRegisterPost200Response authRegisterPost(input)

用户注册

创建新用户账号，需要提供用户名、邮箱和密码

### Example
```dart
import 'package:prismbox_api/api.dart';

final api_instance = AuthApi();
final input = InternalApiV1AuthRegisterInput(); // InternalApiV1AuthRegisterInput | 注册信息

try {
    final result = api_instance.authRegisterPost(input);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->authRegisterPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **input** | [**InternalApiV1AuthRegisterInput**](InternalApiV1AuthRegisterInput.md)| 注册信息 | 

### Return type

[**AuthRegisterPost200Response**](AuthRegisterPost200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

