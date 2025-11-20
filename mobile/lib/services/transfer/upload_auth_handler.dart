// lib/services/transfer/upload_auth_handler.dart

import 'package:background_downloader/background_downloader.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/data/models/auth/auth_model.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:drift/drift.dart' as d;

/// 独立的上传认证处理器
/// 负责处理background_downloader任务的动态认证
@pragma("vm:entry-point")
@lazySingleton
class UploadAuthHandler {
  final SecureStorageService _storageService;
  final _log = Logger('UploadAuthHandler');
  
  /// 专门用于token刷新的Dio实例，避免循环依赖
  late final Dio _tokenDio;
  
  /// 认证失败回调
  Function? onAuthFailure;

  /// 全局数据库实例，用于native回调访问
  static AppDatabase? _globalDb;

  UploadAuthHandler(this._storageService) {
    _initializeTokenDio();
  }

  /// 设置全局数据库实例
  static void setGlobalDatabase(AppDatabase db) {
    _globalDb = db;
  }

  void _initializeTokenDio() {
    _tokenDio = Dio();
    _tokenDio.options.baseUrl = ApiConfig.baseUrlSync;
    _tokenDio.options.connectTimeout = const Duration(seconds: 10);
    _tokenDio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// 获取有效的访问token
  /// 如果当前token无效或即将过期，会自动刷新
  Future<String?> getValidAccessToken() async {
    return await _getValidAccessToken();
  }

  /// background_downloader的onTaskStart回调
  /// 在任务开始执行前动态更新认证信息
  @pragma("vm:entry-point")
  static Future<Task?> onTaskStart(Task original) async {
    if (original is! UploadTask) {
      return original;
    }

    try {
      // 直接使用静态方法处理认证，避免依赖注入
      final accessToken = await _getValidAccessTokenStatic();
      
      if (accessToken == null) {
        // 无法获取有效token，返回null让任务继续执行（可能会失败）
        return null;
      }

      // 更新任务的认证头
      final updatedHeaders = Map<String, String>.from(original.headers);
      updatedHeaders['Authorization'] = 'Bearer $accessToken';
      
      final updatedTask = original.copyWith(headers: updatedHeaders);
      
      return updatedTask;
    } catch (e) {
      // 认证处理失败时返回null，让任务继续执行
      return null;
    }
  }

  /// 静态方法：获取有效的访问token
  /// 避免在native回调中使用依赖注入
  @pragma("vm:entry-point")
  static Future<String?> _getValidAccessTokenStatic() async {
    try {
      // 1. 首先尝试获取当前token
      final currentToken = await _getCurrentTokenStatic();
      
      if (currentToken != null) {
        // 2. 验证当前token是否仍然有效
        if (await _isTokenValidStatic(currentToken)) {
          return currentToken;
        }
      }

      // 3. 尝试刷新token
      return await _refreshAccessTokenStatic();
    } catch (e) {
      return null;
    }
  }

  /// 静态方法：获取当前token
  @pragma("vm:entry-point")
  static Future<String?> _getCurrentTokenStatic() async {
    try {
      if (_globalDb == null) {
        return null;
      }
      return await _globalDb!.userSettingDao.getSetting('album_access_token');
    } catch (e) {
      return null;
    }
  }

  /// 静态方法：验证token是否仍然有效
  @pragma("vm:entry-point")
  static Future<bool> _isTokenValidStatic(String token) async {
    try {
      final dio = Dio();
      dio.options.baseUrl = ApiConfig.baseUrlSync;
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);
      
      final response = await dio.get(
        '/auth/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      return response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
    } catch (e) {
      return false;
    }
  }

  /// 静态方法：刷新访问token
  @pragma("vm:entry-point")
  static Future<String?> _refreshAccessTokenStatic() async {
    try {
      if (_globalDb == null) {
        return null;
      }
      
      final refreshToken = await _globalDb!.userSettingDao.getSetting('album_refresh_token');
      if (refreshToken == null) {
        return null;
      }

      final dio = Dio();
      dio.options.baseUrl = ApiConfig.baseUrlSync;
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);
      
      final response = await dio.post(
        '/auth/refresh',
        data: RefreshTokenInput(refreshToken: refreshToken).toJson(),
      );

      final newData = RefreshTokenSuccessData.fromJson(response.data['data']);
      
      // 保存新的token
      await _globalDb!.userSettingDao.upsertSetting(
        UserSettingsCompanion(
          key: const d.Value('album_access_token'),
          value: d.Value(newData.accessToken),
        ),
      );
      
      return newData.accessToken;
    } catch (e) {
      return null;
    }
  }

  /// 获取有效的访问token
  /// 如果当前token无效或即将过期，会自动刷新
  Future<String?> _getValidAccessToken() async {
    try {
      // 1. 首先尝试获取当前token
      final currentToken = await _storageService.getAccessToken();
      
      if (currentToken != null) {
        // 2. 验证当前token是否仍然有效
        if (await _isTokenValid(currentToken)) {
          _log.fine('当前访问token仍然有效');
          return currentToken;
        }
        _log.info('当前访问token已失效，尝试刷新');
      } else {
        _log.info('未找到访问token，尝试刷新');
      }

      // 3. 尝试刷新token
      return await _refreshAccessToken();
    } catch (e, st) {
      _log.severe('获取有效访问token失败', e, st);
      return null;
    }
  }

  /// 验证token是否仍然有效
  /// 通过发送一个轻量级请求来验证
  Future<bool> _isTokenValid(String token) async {
    try {
      // 使用一个轻量级的API端点来验证token
      final response = await _tokenDio.get(
        '/auth/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      // 200-299状态码表示token有效
      return response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
    } catch (e) {
      _log.fine('Token验证失败: $e');
      return false;
    }
  }

  /// 刷新访问token
  /// 复用DioClient中的token刷新逻辑
  Future<String?> _refreshAccessToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        _log.warning('未找到刷新token');
        await _handleAuthFailure();
        return null;
      }

      _log.info('开始刷新访问token');
      
      final response = await _tokenDio.post(
        '/auth/refresh',
        data: RefreshTokenInput(refreshToken: refreshToken).toJson(),
      );

      final newData = RefreshTokenSuccessData.fromJson(response.data['data']);
      
      // 保存新的token
      await _storageService.saveTokens(
        accessToken: newData.accessToken,
        refreshToken: refreshToken, // 保持原有的refresh token
      );

      _log.info('访问token刷新成功');
      return newData.accessToken;
    } catch (e, st) {
      _log.severe('刷新访问token失败', e, st);
      await _handleAuthFailure();
      return null;
    }
  }

  /// 处理认证失败
  /// 清理本地token并触发认证失败回调
  Future<void> _handleAuthFailure() async {
    try {
      _log.warning('认证失败，清理本地token');
      await _storageService.clearTokens();
      onAuthFailure?.call();
    } catch (e, st) {
      _log.severe('处理认证失败时发生错误', e, st);
    }
  }

  /// 设置认证失败回调
  void setAuthFailureCallback(Function callback) {
    onAuthFailure = callback;
  }
}
