# prismbox_api.api.ServerApi

## Load the API package
```dart
import 'package:prismbox_api/api.dart';
```

All URIs are relative to *http://localhost:8080/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**serverPingGet**](ServerApi.md#serverpingget) | **GET** /server/ping | 服务器健康检查
[**versionGet**](ServerApi.md#versionget) | **GET** /version | 获取版本信息


# **serverPingGet**
> Map<String, Object> serverPingGet()

服务器健康检查

检查服务器是否正常运行

### Example
```dart
import 'package:prismbox_api/api.dart';

final api_instance = ServerApi();

try {
    final result = api_instance.serverPingGet();
    print(result);
} catch (e) {
    print('Exception when calling ServerApi->serverPingGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Map<String, Object>**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **versionGet**
> Map<String, Object> versionGet()

获取版本信息

返回服务器版本信息

### Example
```dart
import 'package:prismbox_api/api.dart';

final api_instance = ServerApi();

try {
    final result = api_instance.versionGet();
    print(result);
} catch (e) {
    print('Exception when calling ServerApi->versionGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Map<String, Object>**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

