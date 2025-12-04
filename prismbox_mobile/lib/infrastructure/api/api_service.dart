import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/core/storage/secure_storage_service.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_error_handler.dart';
import 'package:prismbox/infrastructure/api/network/endpoint_discovery.dart';
import 'package:prismbox/infrastructure/api/utils/url_helper.dart';

/// 统一API服务管理
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Logger _log = Logger('ApiService');
  final Dio _dio = Dio();
  String? _accessToken;
  String? _endpoint;
  EndpointDiscovery? _endpointDiscovery;

  /// 初始化ApiService
  void initialize() {
    _endpointDiscovery = EndpointDiscovery(this);

    // 配置Dio
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(minutes: 30);
    _dio.options.responseType = ResponseType.json;

    // 添加拦截器
    _dio.interceptors.add(_AuthInterceptor(this));
    _dio.interceptors.add(_ErrorInterceptor());

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

  /// 设置API端点
  void setEndpoint(String endpoint) {
    _endpoint = UrlHelper.sanitizeUrl(endpoint);
    _dio.options.baseUrl = _endpoint!;
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

/// 错误拦截器
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401错误：清除Token并可能需要跳转登录
    if (err.response?.statusCode == 401) {
      ApiService().clearAccessToken();
      // TODO: 触发登录跳转逻辑
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

