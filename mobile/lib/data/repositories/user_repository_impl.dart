// lib/data/repositories/user_repository_impl.dart

import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:mobile/data/models/user/user_profile_model.dart';
import 'package:mobile/data/services/user_api_service.dart';
import 'package:mobile/domain/entities/user_profile_entity.dart';
import 'package:mobile/domain/repositories/user_repository.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserApiService _apiService;

  UserRepositoryImpl(this._apiService);

  @override
  Future<UserProfileEntity> getCurrentUser() async {
    final response = await _apiService.getMe();

    final userModel = UserProfileModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );

    return userModel.toEntity();
  }

  @override
  Future<String> uploadAvatar(File imageFile) async {
    final response = await _apiService.uploadAvatar(imageFile);
    final newAvatarUrl = response.data['data']['avatar_url'] as String;

    return newAvatarUrl;
  }
}
