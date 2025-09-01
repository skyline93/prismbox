// lib/data/repositories/user_repository_impl.dart

import 'package:injectable/injectable.dart';
import 'package:mobile/data/models/user/user_model.dart';
import 'package:mobile/data/services/user_api_service.dart';
import 'package:mobile/domain/entities/user_entity.dart';
import 'package:mobile/domain/repositories/user_repository.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserApiService _apiService;

  UserRepositoryImpl(this._apiService);

  @override
  Future<UserEntity> getCurrentUser() async {
    final response = await _apiService.getMe();
    
    // 假设您的API响应结构为 { "status": "success", "message": "...", "data": { ... } }
    // 如果不是，请调整这里的解析逻辑
    final userModel = UserModel.fromJson(response.data['data'] as Map<String, dynamic>);

    // 将数据模型转换为领域实体
    return UserEntity(
      id: userModel.id,
      username: userModel.username,
      avatarUrl: userModel.avatarUrl,
    );
  }
}
