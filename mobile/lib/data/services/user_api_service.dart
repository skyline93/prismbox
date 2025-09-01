// lib/data/services/user_api_service.dart

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class UserApiService {
  final Dio _dio;

  UserApiService(this._dio);

  /// [后端支持] 定义获取当前登录用户信息的接口
  Future<Response> getMe() {
    return _dio.get('/users/me');
  }
}
