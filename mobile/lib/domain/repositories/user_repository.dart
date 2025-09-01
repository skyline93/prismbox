// lib/domain/repositories/user_repository.dart

import 'package:mobile/domain/entities/user_entity.dart';

abstract class UserRepository {
  /// 获取当前已登录用户的信息
  Future<UserEntity> getCurrentUser();
}
