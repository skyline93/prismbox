// lib/domain/repositories/user_repository.dart

import 'dart:io';
import 'package:mobile/domain/entities/user_profile_entity.dart';

abstract class UserRepository {
  /// 获取当前已登录用户的信息
  Future<UserProfileEntity> getCurrentUser();
  // [新增] 定义上传头像方法的接口，它接收一个文件并返回新的头像URL
  Future<String> uploadAvatar(File imageFile);
}
