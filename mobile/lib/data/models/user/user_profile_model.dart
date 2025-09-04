// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/domain/entities/user_profile_entity.dart'; // 引入统一后的实体

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

@freezed
class UserProfileModel with _$UserProfileModel {
  // 添加私有构造函数，以便我们添加 toEntity 方法
  const UserProfileModel._();

  const factory UserProfileModel({
    // [保留] 原有字段
    required int id,
    required String username,

    // [新增] 添加 email 字段
    required String email,

    // [保留] avatarUrl 字段，并确保 @JsonKey 正确
    @JsonKey(name: 'avatar_url') String? avatarUrl,

    // [新增] 添加存储信息的字段，并使用 @JsonKey 映射API响应的 snake_case 命名
    @JsonKey(name: 'used_storage') required double usedStorage,
    @JsonKey(name: 'total_storage') required double totalStorage,
  }) = _UserProfileModel;

  /// 工厂构造函数：用于从JSON创建实例
  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  /// [核心] 添加 toEntity 方法
  /// 这个方法负责将数据层模型（关心API结构）转换为领域层实体（关心业务逻辑）
  UserProfileEntity toEntity() {
    return UserProfileEntity(
      id: id,
      username: username,
      email: email,
      // 如果 avatarUrl 为 null，则在实体中也为 null
      avatarUrl: avatarUrl,
      usedStorage: usedStorage,
      totalStorage: totalStorage,
    );
  }
}
