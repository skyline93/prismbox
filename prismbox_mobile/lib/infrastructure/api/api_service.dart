import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logging/logging.dart';
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

  /// 设置401错误回调
  void setOnUnauthorizedCallback(OnUnauthorizedCallback? callback) {
    _onUnauthorized = callback;
  }

  /// 初始化ApiService
  void initialize() {
    _endpointDiscovery = EndpointDiscovery(this);

    // 配置标准API Dio
    _configureDio(_dio);

    // 配置文件上传Dio（超时时间更长）
    _configureDio(_fileDio);
    _fileDio.options.receiveTimeout = const Duration(hours: 1);
    _fileDio.options.sendTimeout = const Duration(hours: 1);

    // 如果已有保存的端点，恢复它
    final store = StoreService();
    if (store.isInitialized) {
      final endpoint = store.tryGet<String>(StoreKey.serverEndpoint);
      if (endpoint != null && endpoint.isNotEmpty) {
        setEndpoint(endpoint);
      }

      // 恢复Token
      final token = store.tryGet<String>(StoreKey.accessToken);
      if (token != null) {
        _accessToken = token;
      }
    }

    _log.info('ApiService initialized');
  }

  /// 配置Dio实例
  void _configureDio(Dio dio) {
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
    dio.interceptors.add(_LoggingInterceptor());
    dio.interceptors.add(_AuthInterceptor(this));
    dio.interceptors.add(_ResponseInterceptor());
    dio.interceptors.add(_RetryInterceptor());
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
  Future<String> resolveAndSetEndpoint(String serverUrl) async {
    if (_endpointDiscovery == null) {
      _endpointDiscovery = EndpointDiscovery(this);
    }

    // 解析端点（包括well-known发现）
    final endpoint = await _endpointDiscovery!.discoverAndValidate(serverUrl);

    // 设置端点
    setEndpoint(endpoint);

    // 持久化端点
    final store = StoreService();
    if (store.isInitialized) {
      await store.put(StoreKey.serverEndpoint, endpoint);
    }

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
        headers['x-immich-user-token'] = token;
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
      final response = await _dio.get('/server/ping');
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
      options.headers['x-immich-user-token'] = token;
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
      response.data = responseData;
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
class _LoggingInterceptor extends Interceptor {
  final Logger _log = Logger('ApiService');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.fine('Request: ${options.method} ${options.uri}');
    if (options.data != null && options.data is! FormData) {
      _log.fine('Request Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log.fine(
      'Response: ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.warning(
      'Error: ${err.type} ${err.requestOptions.uri}',
      err,
      err.stackTrace,
    );
    handler.next(err);
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

