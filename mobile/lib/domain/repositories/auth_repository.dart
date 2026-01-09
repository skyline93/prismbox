// lib/domain/repositories/auth_repository.dart

import 'dart:io';
import 'package:prismbox/infrastructure/api/models/auth/auth_response_dto.dart';
import 'package:prismbox/infrastructure/api/models/auth/login_request_dto.dart';
import 'package:prismbox/infrastructure/api/models/auth/register_request_dto.dart';
import 'package:prismbox/infrastructure/api/models/auth/register_response_dto.dart';
import 'package:prismbox/infrastructure/api/models/auth/refresh_token_response_dto.dart';
import 'package:prismbox/infrastructure/api/models/auth/user_profile_dto.dart';

/// 认证仓库接口
abstract class AuthRepository {
  /// 用户登录
  /// 
  /// [request] 登录请求
  /// 
  /// 返回 [AuthResponseDto] 包含访问令牌和刷新令牌
  /// 
  /// 抛出 [ApiException] 如果邮箱或密码错误
  Future<AuthResponseDto> login(LoginRequestDto request);

  /// 用户注册
  /// 
  /// [request] 注册请求
  /// 
  /// 返回 [RegisterResponseDto] 包含用户ID和用户名
  /// 
  /// 抛出 [ApiException] 如果用户名或邮箱已存在
  Future<RegisterResponseDto> register(RegisterRequestDto request);

  /// 刷新访问令牌
  /// 
  /// [refreshToken] 刷新令牌
  /// 
  /// 返回 [RefreshTokenResponseDto] 包含新的访问令牌
  /// 
  /// 抛出 [ApiException] 如果刷新令牌无效或已过期
  Future<RefreshTokenResponseDto> refreshToken(String refreshToken);

  /// 用户登出
  /// 
  /// [refreshToken] 刷新令牌
  /// 
  /// 抛出 [ApiException] 如果刷新令牌无效
  Future<void> logout(String refreshToken);

  /// 获取用户资料
  /// 
  /// 返回 [UserProfileDto] 包含用户资料信息
  /// 
  /// 抛出 [ApiException] 如果未认证或用户不存在
  Future<UserProfileDto> getProfile();

  /// 上传用户头像
  /// 
  /// [imageFile] 头像图片文件
  /// 
  /// 返回新的头像 URL
  /// 
  /// 抛出 [ApiException] 如果上传失败
  Future<String> uploadAvatar(File imageFile);
}

