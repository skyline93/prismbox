import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/config/app_config.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/core/storage/secure_storage_service.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_error_handler.dart';
import 'package:prismbox/infrastructure/api/network/endpoint_discovery.dart';
import 'package:prismbox/infrastructure/api/utils/url_helper.dart';

/// 401错误回调函数类型
typedef OnUnauthorizedCallback = void Function();

/// 统一API服务管理
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Logger _log = Logger('ApiService');
  final Dio _dio = Dio();
  final Dio _fileDio = Dio(); // 文件上传专用Dio实例
  String? _accessToken;
  String? _endpoint;
  EndpointDiscovery? _endpointDiscovery;
  OnUnauthorizedCallback? _onUnauthorized;
  bool _isInitialized = false; // 初始化标志，避免重复初始化

  /// 设置401错误回调
  void setOnUnauthorizedCallback(OnUnauthorizedCallback? callback) {
    _onUnauthorized = callback;
  }

  /// 初始化ApiService
  void initialize() {
    // 如果已经初始化，直接返回，避免重复初始化
    if (_isInitialized) {
      return;
    }

    _endpointDiscovery = EndpointDiscovery(this);

    // 配置标准API Dio
    _configureDio(_dio);

    // 配置文件上传Dio（超时时间更长）
    _configureDio(_fileDio);
    _fileDio.options.receiveTimeout = const Duration(hours: 1);
    _fileDio.options.sendTimeout = const Duration(hours: 1);

    // 从 AppConfig 读取端点并设置
    final endpoint = ApiConfig.apiEndpoint;
    setEndpoint(endpoint);
    _log.info('API endpoint initialized from AppConfig: $endpoint');

    // 恢复Token（从 Store）
    final store = StoreService();
    if (store.isInitialized) {
      final token = store.tryGet<String>(StoreKey.accessToken);
      if (token != null) {
        _accessToken = token;
      }
    }

    _isInitialized = true; // 标记为已初始化
    _log.info('ApiService initialized');
  }

  /// 配置Dio实例
  void _configureDio(Dio dio) {
    // 清除已有拦截器，避免重复添加
    dio.interceptors.clear();
    
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(minutes: 30);
    dio.options.responseType = ResponseType.json;
    dio.options.headers['User-Agent'] = 'PrismBox-Mobile/1.0';

    // 配置HttpClient以支持HttpOverrides和连接池
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.maxConnectionsPerHost = 16;
      client.autoUncompress = true;
      // HttpOverrides.global会自动应用
      return client;
    };

    // 添加拦截器（注意顺序很重要）
    // 1. 认证拦截器（最先，添加认证头）
    dio.interceptors.add(_AuthInterceptor(this));
    // 2. 响应格式拦截器（处理统一响应格式，提取 data 字段）
    dio.interceptors.add(_ResponseInterceptor());
    // 3. 日志拦截器（记录处理后的数据，放在 ResponseInterceptor 之后）
    dio.interceptors.add(_LoggingInterceptor());
    // 4. 重试拦截器（处理网络错误重试）
    dio.interceptors.add(_RetryInterceptor());
    // 5. 错误拦截器（最后，统一错误处理）
    dio.interceptors.add(_ErrorInterceptor(this));
  }

  /// 设置API端点
  void setEndpoint(String endpoint) {
    _endpoint = UrlHelper.sanitizeUrl(endpoint);
    _dio.options.baseUrl = _endpoint!;
    _fileDio.options.baseUrl = _endpoint!;
    _log.info('API endpoint set to: $_endpoint');
  }

  /// 获取当前端点
  String? get endpoint => _endpoint;

  /// 解析并设置端点
  /// 
  /// 注意：此方法仅用于端点发现和临时设置，不会持久化到 Store
  /// 服务器地址应在 app_config.dart 中配置
  Future<String> resolveAndSetEndpoint(String serverUrl) async {
    if (_endpointDiscovery == null) {
      _endpointDiscovery = EndpointDiscovery(this);
    }

    // 解析端点（包括well-known发现）
    final endpoint = await _endpointDiscovery!.discoverAndValidate(serverUrl);

    // 设置端点（仅设置到内存，不持久化）
    setEndpoint(endpoint);

    // 注意：不再保存到 Store，因为服务器地址应该在 app_config.dart 中配置
    _log.info('API endpoint resolved and set: $endpoint (not persisted)');

    return endpoint;
  }

  /// 解析端点（支持well-known发现）
  Future<String> resolveEndpoint(String serverUrl) async {
    if (_endpointDiscovery == null) {
      _endpointDiscovery = EndpointDiscovery(this);
    }
    return await _endpointDiscovery!.discoverAndValidate(serverUrl);
  }

  /// 设置Access Token
  Future<void> setAccessToken(String accessToken) async {
    _accessToken = accessToken;

    // 存储到本地Store（用于应用内访问）
    final store = StoreService();
    if (store.isInitialized) {
      await store.put(StoreKey.accessToken, accessToken);
    }

    // 存储到平台安全存储（用于Widget扩展等）
    await SecureStorageService().setAccessToken(accessToken);

    _log.fine('Access token set');
  }

  /// 获取Access Token
  String? getAccessToken() {
    return _accessToken;
  }

  /// 清除Access Token
  Future<void> clearAccessToken() async {
    _accessToken = null;

    final store = StoreService();
    if (store.isInitialized) {
      await store.delete(StoreKey.accessToken);
    }

    await SecureStorageService().deleteAccessToken();
    _log.info('Access token cleared');
  }

  /// 获取请求头（用于background_downloader等）
  static Map<String, String> getRequestHeaders() {
    final headers = <String, String>{};

    // 添加认证头
    final store = StoreService();
    if (store.isInitialized) {
      final token = store.tryGet<String>(StoreKey.accessToken);
      if (token != null) {
        headers['x-prismbox-user-token'] = token;
      }

      // 添加自定义头
      final customHeaders = store.tryGet<String>(StoreKey.customHeaders);
      if (customHeaders != null) {
        try {
          final custom = jsonDecode(customHeaders) as Map<String, dynamic>;
          custom.forEach((key, value) {
            headers[key] = value.toString();
          });
        } catch (e) {
          // 忽略解析错误
        }
      }
    }

    return headers;
  }

  /// 设置设备信息头
  Future<void> setDeviceInfoHeader() async {
    try {
      String? deviceModel;
      String deviceType = 'mobile';

      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = androidInfo.model;
        deviceType = 'android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.model;
        deviceType = 'ios';
      }

      if (deviceModel != null) {
        final store = StoreService();
        if (store.isInitialized) {
          await store.put(StoreKey.deviceModel, deviceModel);
          await store.put(StoreKey.deviceType, deviceType);
        }
      }
    } catch (e) {
      _log.warning('Failed to set device info header: $e');
    }
  }

  /// 服务器健康检查（pingServer）
  Future<void> pingServer() async {
    if (_endpoint == null) {
      throw StateError('API endpoint not set');
    }

    try {
      final response = await _dio.get('/api/v1/server/ping');
      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode ?? 500,
          'Server ping failed',
        );
      }
    } on DioException catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }

  /// 获取Dio实例（用于直接调用API）
  Dio get dio => _dio;

  /// 获取文件上传Dio实例（用于大文件上传）
  Dio get fileDio => _fileDio;

  /// 获取401错误回调（供拦截器使用）
  OnUnauthorizedCallback? get onUnauthorized => _onUnauthorized;
}

/// 认证拦截器
class _AuthInterceptor extends Interceptor {
  final ApiService _apiService;

  _AuthInterceptor(this._apiService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 注入认证头
    final token = _apiService.getAccessToken();
    if (token != null) {
      options.headers['x-prismbox-user-token'] = token;
    }

    // 注入自定义头
    final store = StoreService();
    if (store.isInitialized) {
      final customHeaders = store.tryGet<String>(StoreKey.customHeaders);
      if (customHeaders != null) {
        try {
          final custom = jsonDecode(customHeaders) as Map<String, dynamic>;
          custom.forEach((key, value) {
            options.headers[key] = value.toString();
          });
        } catch (e) {
          // 忽略解析错误
        }
      }

      // 注入设备信息头
      final deviceModel = store.tryGet<String>(StoreKey.deviceModel);
      final deviceType = store.tryGet<String>(StoreKey.deviceType);
      if (deviceModel != null) {
        options.headers['deviceModel'] = deviceModel;
      }
      if (deviceType != null) {
        options.headers['deviceType'] = deviceType;
      }
    }

    handler.next(options);
  }
}

/// 响应格式拦截器（处理后端统一ApiResponse格式）
class _ResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 解析后端统一响应格式 ApiResponse{code, message, data}
    if (response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      final code = data['code'] as int?;
      final message = data['message'] as String?;
      final responseData = data['data'];

      // 如果 code != 0，视为业务错误
      if (code != null && code != 0) {
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: Response(
              requestOptions: response.requestOptions,
              statusCode: 400, // 业务错误统一为400
              statusMessage: message ?? '请求失败',
              data: {'message': message ?? '请求失败', 'code': code},
              headers: response.headers,
              isRedirect: response.isRedirect,
              redirects: response.redirects,
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return;
      }

      // 成功时，将data字段提取出来，直接返回业务数据
      // 如果 data 字段为 null，保持原响应不变（可能是某些接口的特殊情况，如 logout）
      if (responseData != null) {
        response.data = responseData;
      } else {
        // 如果 data 为 null，保持完整的 ApiResponse 格式
        // 这样调用方可以自己处理（某些接口可能确实返回 null data）
        response.data = data;
      }
    }

    handler.next(response);
  }
}

/// 重试拦截器
class _RetryInterceptor extends Interceptor {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) && _getRetryCount(err) < _maxRetries) {
      final retryCount = _getRetryCount(err) + 1;

      // 指数退避
      final delay = _retryDelay * retryCount;
      await Future.delayed(delay);

      // 更新重试计数
      err.requestOptions.extra['retryCount'] = retryCount;

      try {
        // 创建新的Dio实例进行重试
        final dio = Dio();
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        if (e is DioException) {
          handler.next(e);
        } else {
          handler.next(err);
        }
        return;
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // 网络错误、超时、5xx错误可重试
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }

  int _getRetryCount(DioException err) {
    return err.requestOptions.extra['retryCount'] as int? ?? 0;
  }
}

/// 日志拦截器
/// 用于统一打印 API 请求和响应的详细信息（Debug 级别）
class _LoggingInterceptor extends Interceptor {
  final Logger _log = Logger('ApiService');
  
  // 最大响应体长度（超过此长度会截断）
  static const int _maxResponseBodyLength = 2000;
  
  // 需要隐藏的敏感字段
  static const List<String> _sensitiveFields = [
    'password',
    'token',
    'accessToken',
    'refreshToken',
    'authorization',
    'x-prismbox-user-token',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 只在调试模式下输出详细的请求日志
    if (kDebugMode) {
      final uri = options.uri.toString();
      final method = options.method;
      
      _log.fine('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log.fine('📤 API Request');
      _log.fine('  Method: $method');
      _log.fine('  URL: $uri');
      
      // 打印请求头（隐藏敏感信息）
      if (options.headers.isNotEmpty) {
        final safeHeaders = _sanitizeHeaders(options.headers);
        _log.fine('  Headers: $safeHeaders');
      }
      
      // 打印请求体
      if (options.data != null) {
        if (options.data is FormData) {
          _log.fine('  Body: [FormData]');
        } else {
          final bodyStr = _formatJson(options.data);
          _log.fine('  Body: $bodyStr');
        }
      }
      
      _log.fine('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 只在调试模式下输出详细的响应日志
    if (kDebugMode) {
      final uri = response.requestOptions.uri.toString();
      final statusCode = response.statusCode;
      final method = response.requestOptions.method;
      
      _log.fine('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log.fine('📥 API Response');
      _log.fine('  Method: $method');
      _log.fine('  URL: $uri');
      _log.fine('  Status: $statusCode ${_getStatusMessage(statusCode)}');
      
      // 打印响应头（隐藏敏感信息）
      if (response.headers.map.isNotEmpty) {
        final safeHeaders = _sanitizeHeaders(
          response.headers.map.map((k, v) => MapEntry(k, v.join(', '))),
        );
        _log.fine('  Headers: $safeHeaders');
      }
      
      // 打印响应体
      if (response.data != null) {
        final responseBody = _formatResponseBody(response.data);
        if (responseBody.length > _maxResponseBodyLength) {
          // 响应体过长，截断并提示
          final truncated = responseBody.substring(0, _maxResponseBodyLength);
          _log.fine('  Body: $truncated...');
          _log.fine('  [响应体过长，已截断。完整长度: ${responseBody.length} 字符]');
        } else {
          _log.fine('  Body: $responseBody');
        }
      } else {
        _log.fine('  Body: [空]');
      }
      
      _log.fine('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 错误日志使用 warning 级别，但详细信息只在调试模式下输出
    final uri = err.requestOptions.uri.toString();
    final method = err.requestOptions.method;
    
    _log.warning('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _log.warning('❌ API Error');
    _log.warning('  Method: $method');
    _log.warning('  URL: $uri');
    _log.warning('  Type: ${err.type}');
    
    if (err.response != null) {
      final statusCode = err.response!.statusCode;
      _log.warning('  Status: $statusCode ${_getStatusMessage(statusCode)}');
      
      // 在调试模式下打印错误响应体
      if (kDebugMode && err.response!.data != null) {
        final errorBody = _formatResponseBody(err.response!.data);
        if (errorBody.length > _maxResponseBodyLength) {
          final truncated = errorBody.substring(0, _maxResponseBodyLength);
          _log.warning('  Error Body: $truncated...');
          _log.warning('  [错误响应体过长，已截断。完整长度: ${errorBody.length} 字符]');
        } else {
          _log.warning('  Error Body: $errorBody');
        }
      }
    } else {
      _log.warning('  Message: ${err.message}');
    }
    
    if (err.error != null) {
      _log.warning('  Error: ${err.error}');
    }
    
    // 在调试模式下输出堆栈跟踪
    if (kDebugMode) {
      try {
        _log.warning('  StackTrace: ${err.stackTrace}');
      } catch (e) {
        // 忽略堆栈跟踪输出错误
      }
    }
    
    _log.warning('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    handler.next(err);
  }

  /// 格式化 JSON 数据
  String _formatJson(dynamic data) {
    try {
      if (data is String) {
        // 尝试解析为 JSON
        final decoded = jsonDecode(data);
        return _formatJson(decoded);
      } else if (data is Map || data is List) {
        // 隐藏敏感信息
        final sanitized = _sanitizeData(data);
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(sanitized);
      } else {
        return data.toString();
      }
    } catch (e) {
      // 如果不是 JSON，直接返回字符串
      return data.toString();
    }
  }

  /// 格式化响应体
  String _formatResponseBody(dynamic data) {
    if (data is String) {
      // 尝试解析为 JSON
      try {
        final decoded = jsonDecode(data);
        return _formatJson(decoded);
      } catch (e) {
        return data;
      }
    } else {
      return _formatJson(data);
    }
  }

  /// 隐藏敏感信息
  dynamic _sanitizeData(dynamic data) {
    if (data is Map) {
      final sanitized = <String, dynamic>{};
      data.forEach((key, value) {
        final keyStr = key.toString().toLowerCase();
        if (_sensitiveFields.any((field) => keyStr.contains(field.toLowerCase()))) {
          sanitized[key.toString()] = '***HIDDEN***';
        } else if (value is Map || value is List) {
          sanitized[key.toString()] = _sanitizeData(value);
        } else {
          sanitized[key.toString()] = value;
        }
      });
      return sanitized;
    } else if (data is List) {
      return data.map((item) => _sanitizeData(item)).toList();
    } else {
      return data;
    }
  }

  /// 隐藏请求头中的敏感信息
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = <String, dynamic>{};
    headers.forEach((key, value) {
      final keyStr = key.toLowerCase();
      if (_sensitiveFields.any((field) => keyStr.contains(field.toLowerCase()))) {
        sanitized[key] = '***HIDDEN***';
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  /// 获取 HTTP 状态码描述
  String _getStatusMessage(int? statusCode) {
    if (statusCode == null) return '';
    
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        return '';
    }
  }
}

/// 错误拦截器
class _ErrorInterceptor extends Interceptor {
  final ApiService _apiService;

  _ErrorInterceptor(this._apiService);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401错误：清除Token并触发登录跳转
    if (err.response?.statusCode == 401) {
      _apiService.clearAccessToken();

      // 触发401回调
      final callback = _apiService.onUnauthorized;
      if (callback != null) {
        callback();
      }
    }

    // 转换为统一的ApiException
    final apiException = ApiErrorHandler.handleError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
      ),
    );
  }
}

