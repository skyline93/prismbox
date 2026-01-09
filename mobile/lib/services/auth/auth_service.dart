// lib/services/auth/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:prismbox/core/storage/secure_storage_service.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/domain/entities/auth_result.dart';
import 'package:prismbox/domain/entities/user_profile.dart';
import 'package:prismbox/domain/repositories/auth_repository.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';
import 'package:prismbox/infrastructure/api/models/auth/login_request_dto.dart';
import 'package:prismbox/infrastructure/api/models/auth/register_request_dto.dart';

/// 认证服务
/// 封装登录注册业务逻辑、Token管理、用户信息管理
class AuthService {
  final AuthRepository _repository;
  final ApiService _apiService;
  final SecureStorageService _secureStorage;
  final AppDatabase _database;
  final Logger _log = Logger('AuthService');

  Future<UserProfile>? _profileFuture;
  
  // 认证检查缓存
  DateTime? _lastAuthCheck;
  bool? _lastAuthResult;
  static const Duration _authCheckCacheDuration = Duration(seconds: 30); // 30秒缓存

  AuthService({
    required AuthRepository repository,
    required ApiService apiService,
    required SecureStorageService secureStorage,
    required AppDatabase database,
  })  : _repository = repository,
        _apiService = apiService,
        _secureStorage = secureStorage,
        _database = database;

  // ========== 登录注册 ==========

  /// 用户登录
  /// 
  /// [email] 邮箱地址
  /// [password] 密码
  /// 
  /// 返回 [AuthResult] 包含登录结果和用户信息
  Future<AuthResult> login(String email, String password) async {
    try {
      // 1. 调用登录 API
      final request = LoginRequestDto(email: email, password: password);
      final response = await _repository.login(request);

      // 2. 保存 Token（确保在获取 profile 前完成）
      await _apiService.setAccessToken(response.accessToken);
      await _secureStorage.setRefreshToken(response.refreshToken);
      
      // 等待一小段时间，确保 token 已完全设置到拦截器中
      // 这样可以避免后续请求时 token 还未生效的问题
      await Future.delayed(const Duration(milliseconds: 50));

      // 3. 获取用户资料（不使用缓存，确保获取最新数据）
      final profile = await getProfile(useCache: false);

      // 4. 保存用户信息到本地数据库
      await _saveUserToDatabase(profile);

      // 5. 保存用户信息到 Store
      await _saveUserToStore(profile);

      // 6. 清除认证检查缓存，确保后续检查使用新的认证状态
      _clearAuthCache();

      return AuthSuccess(profile);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return const AuthFailure('邮箱或密码错误');
      }
      return AuthFailure(e.message);
    } catch (e) {
      _log.severe('Login failed: $e', e);
      return AuthFailure('登录失败: $e');
    }
  }

  /// 用户注册
  /// 
  /// [username] 用户名
  /// [email] 邮箱地址
  /// [password] 密码
  /// 
  /// 返回 [RegisterResult] 包含注册结果
  Future<RegisterResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // 1. 调用注册 API
      final request = RegisterRequestDto(
        username: username,
        email: email,
        password: password,
      );
      await _repository.register(request);

      // 2. 注册成功后自动登录
      final loginResult = await login(email, password);

      if (loginResult.isSuccess) {
        return RegisterSuccess(loginResult.user!);
      } else {
        return RegisterFailure(
          loginResult.errorMessage ?? '注册成功，但登录失败',
        );
      }
    } on ApiException catch (e) {
      if (e.statusCode == 400 || e.statusCode == 409) {
        return const RegisterFailure('用户名或邮箱已存在');
      }
      return RegisterFailure(e.message);
    } catch (e) {
      _log.severe('Register failed: $e', e);
      return RegisterFailure('注册失败: $e');
    }
  }

  // ========== Token 管理 ==========

  /// 刷新访问令牌
  /// 
  /// [refreshToken] 刷新令牌
  /// 
  /// 返回新的访问令牌
  /// 
  /// 抛出 [ApiException] 如果刷新令牌无效或已过期
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _repository.refreshToken(refreshToken);
      await _apiService.setAccessToken(response.accessToken);
      return response.accessToken;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // 刷新令牌失效，清除认证信息
        await clearAuth();
      }
      rethrow;
    }
  }

  /// 登出
  /// 
  /// 撤销刷新令牌并清除本地认证信息
  Future<void> logout() async {
    try {
      // 1. 获取刷新令牌
      final refreshToken = await _secureStorage.getRefreshToken();

      // 2. 调用登出 API（撤销刷新令牌）
      if (refreshToken != null) {
        try {
          await _repository.logout(refreshToken);
        } catch (e) {
          // 即使登出 API 调用失败，也清除本地认证信息
          _log.warning('Logout API call failed: $e');
        }
      }
    } catch (e) {
      _log.warning('Logout error: $e');
    } finally {
      // 3. 清除本地认证信息
      await clearAuth();
    }
  }

  // ========== 用户信息 ==========

  /// 获取用户资料
  /// 
  /// 返回当前登录用户的资料信息
  /// 
  /// 抛出 [ApiException] 如果未认证或用户不存在
  Future<UserProfile> getProfile({bool useCache = true}) async {
    // 如果已有正在进行的请求，等待它完成（去重）
    if (_profileFuture != null) {
      return await _profileFuture!;
    }

    // 创建新请求
    _profileFuture = _fetchProfile(useCache);

    try {
      return await _profileFuture!;
    } finally {
      _profileFuture = null;
    }
  }

  /// 获取用户资料（内部方法）
  Future<UserProfile> _fetchProfile(bool useCache) async {
    // 1. 尝试从本地数据库获取
    if (useCache) {
      // 优先从本地数据库获取用户，避免额外的 API 调用
      final users = await _database.userDao.getAllUsers();
      if (users.isNotEmpty) {
        // 返回最近登录的用户（假设只有一个活跃用户）
        // 如果支持多用户，可以根据 token 或其他标识符筛选
        final localUser = users.first;
        final profile = UserProfile.fromEntity(localUser);
        
        // 确保用户信息也在 Store 中（应用重启后可能不在内存缓存中）
        await _saveUserToStore(profile);
        
        return profile;
      }
    }

    // 2. 从服务器获取
    final dto = await _repository.getProfile();
    final profile = UserProfile.fromDto(dto);

    // 3. 更新本地缓存
    await _saveUserToDatabase(profile);

    // 4. 保存用户信息到 Store
    await _saveUserToStore(profile);

    return profile;
  }

  /// 上传用户头像
  /// 
  /// [imageFile] 头像图片文件
  /// 
  /// 返回新的头像 URL
  /// 
  /// 抛出 [ApiException] 如果上传失败
  Future<String> uploadAvatar(File imageFile) async {
    try {
      _log.info('Uploading avatar');
      final avatarUrl = await _repository.uploadAvatar(imageFile);
      
      // 上传成功后，刷新用户资料
      final profile = await getProfile(useCache: false);
      
      // 更新本地数据库
      await _saveUserToDatabase(profile);
      
      // 更新 Store
      await _saveUserToStore(profile);
      
      // 清除认证检查缓存
      _clearAuthCache();
      
      _log.info('Avatar uploaded successfully: $avatarUrl');
      return avatarUrl;
    } catch (e) {
      _log.severe('Failed to upload avatar: $e', e);
      rethrow;
    }
  }

  /// 检查登录状态
  /// 
  /// 返回 true 如果用户已登录且 Token 有效
  /// 使用 /api/v1/auth/profile 来验证 token，而不是 pingServer
  /// 添加缓存机制，避免短时间内重复调用
  Future<bool> isAuthenticated() async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        _clearAuthCache();
        return false;
      }

      // 使用缓存避免短时间内重复调用
      final now = DateTime.now();
      if (_lastAuthCheck != null && 
          _lastAuthResult != null &&
          now.difference(_lastAuthCheck!) < _authCheckCacheDuration) {
        _log.fine('Using cached authentication result');
        return _lastAuthResult!;
      }

      // 使用 profile 接口验证 token（如果 token 无效会返回 401）
      // 这样比 pingServer 更语义化，而且可以同时验证认证状态
      try {
        await _repository.getProfile();
        _lastAuthResult = true;
        _lastAuthCheck = now;
        return true;
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          _log.fine('Token invalid or expired');
          _clearAuthCache();
          return false;
        }
        rethrow;
      }
    } catch (e) {
      _log.fine('Authentication check failed: $e');
      _clearAuthCache();
      return false;
    }
  }

  // ========== 认证信息管理 ==========

  /// 清除认证信息
  /// 
  /// 清除 Token 和本地用户数据
  Future<void> clearAuth() async {
    await _apiService.clearAccessToken();
    await _secureStorage.deleteAccessToken();
    await _secureStorage.deleteRefreshToken();
    
    // 清除认证检查缓存
    _clearAuthCache();

    // 清除用户信息从 Store
    try {
      final store = StoreService();
      if (store.isInitialized) {
        await store.delete(StoreKey.currentUser);
        _log.fine('User profile cleared from Store');
      }
    } catch (e) {
      _log.warning('Failed to clear user from Store: $e');
    }

    // 注意：不清除本地用户数据，因为：
    // 1. 支持多用户场景
    // 2. 用户数据可能被其他数据引用（资产、相册等）
    // 如果需要清除，可以在登出时显式调用
  }

  // ========== 私有方法 ==========

  /// 保存用户信息到本地数据库
  Future<void> _saveUserToDatabase(UserProfile profile) async {
    try {
      final userEntity = profile.toEntity();

      // 检查用户是否已存在
      final existingUser = await _database.userDao.getUserById(userEntity.id);

      if (existingUser != null) {
        // 更新现有用户
        await _database.userDao.updateUser(userEntity);
      } else {
        // 插入新用户
        await _database.userDao.insertUser(userEntity);
      }
    } catch (e) {
      // 记录错误但不影响登录流程
      _log.warning('Failed to save user to database: $e');
    }
  }

  /// 清除认证检查缓存
  void _clearAuthCache() {
    _lastAuthCheck = null;
    _lastAuthResult = null;
  }

  /// 保存用户信息到 Store
  /// 
  /// 将用户信息序列化为 JSON 字符串并保存到 StoreService
  Future<void> _saveUserToStore(UserProfile profile) async {
    try {
      final store = StoreService();
      if (!store.isInitialized) {
        _log.warning('StoreService not initialized, cannot save user to Store');
        return;
      }

      // 将 UserProfile 转换为 JSON 字符串
      final userMap = {
        'id': profile.id,
        'username': profile.username,
        'email': profile.email,
        'avatarUrl': profile.avatarUrl,
        'createdAt': profile.createdAt?.toIso8601String(),
      };

      final userJson = jsonEncode(userMap);
      await store.put(StoreKey.currentUser, userJson);
      _log.fine('User profile saved to Store');
    } catch (e) {
      _log.warning('Failed to save user to Store: $e');
    }
  }

}

