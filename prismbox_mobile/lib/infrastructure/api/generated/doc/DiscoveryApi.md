# prismbox_api.api.DiscoveryApi

## Load the API package
```dart
import 'package:prismbox_api/api.dart';
```

All URIs are relative to *http://localhost:8080/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**wellKnownPrismboxGet**](DiscoveryApi.md#wellknownprismboxget) | **GET** /.well-known/prismbox | 端点发现


# **wellKnownPrismboxGet**
> Map<String, Object> wellKnownPrismboxGet()

端点发现

返回 API 端点信息，用于客户端自动发现

### Example
```dart
import 'package:prismbox_api/api.dart';

final api_instance = DiscoveryApi();

try {
    final result = api_instance.wellKnownPrismboxGet();
    print(result);
} catch (e) {
    print('Exception when calling DiscoveryApi->wellKnownPrismboxGet: $e\n');
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

