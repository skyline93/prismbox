import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_entity.freezed.dart';
part 'user_profile_entity.g.dart';

@freezed
class UserProfileEntity with _$UserProfileEntity {
  // 私有构造函数，用于添加自定义 getter
  const UserProfileEntity._();

  const factory UserProfileEntity({
    // [合并] 从 UserEntity 中添加了 'id' 字段
    required int id,

    // 保留 UserProfileEntity 的所有字段
    required String username,
    required String email,

    // [修改] 将 avatarUrl 改为可空，以处理用户未设置头像的情况
    // 这也与原 UserEntity 的定义保持了一致，增加了灵活性
    String? avatarUrl,

    // required double usedStorage,
    // required double totalStorage,
  }) = _UserProfileEntity;

  /// 工厂构造函数：用于创建一个表示“初始”或“未加载”状态的实体
  factory UserProfileEntity.initial() => const UserProfileEntity(
    id: 0, // 使用 0 或 -1 作为未加载状态的 ID
    username: '加载中...',
    email: '',
    avatarUrl: null, // 初始时头像 URL 为 null
    // usedStorage: 0.0,
    // totalStorage: 0.0,
  );

  /// 工厂构造函数：用于从JSON创建实例
  factory UserProfileEntity.fromJson(Map<String, dynamic> json) =>
      _$UserProfileEntityFromJson(json);

  // 您的自定义辅助 getter 保持不变
  // double get storagePercentage =>
  //     totalStorage > 0 ? usedStorage / totalStorage : 0;

  // String get storageText =>
  //     '${usedStorage.toStringAsFixed(1)} / ${totalStorage.toStringAsFixed(0)} GB';
}
