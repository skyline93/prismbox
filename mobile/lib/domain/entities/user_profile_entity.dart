class UserProfileEntity {
  final String username;
  final String email;
  final String avatarUrl;
  final double usedStorage;
  final double totalStorage;

  const UserProfileEntity({
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.usedStorage,
    required this.totalStorage,
  });

  // 辅助 getter
  double get storagePercentage =>
      totalStorage > 0 ? usedStorage / totalStorage : 0;
  String get storageText =>
      '${usedStorage.toStringAsFixed(1)} / ${totalStorage.toStringAsFixed(0)} GB';

  // [新增] copyWith 方法
  // 作用：创建一个新的实例，只修改你想要的字段，其余保持不变。
  // 这是 Riverpod 状态管理中不可变性的核心。
  UserProfileEntity copyWith({
    String? username,
    String? email,
    String? avatarUrl,
    double? usedStorage,
    double? totalStorage,
  }) {
    return UserProfileEntity(
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      usedStorage: usedStorage ?? this.usedStorage,
      totalStorage: totalStorage ?? this.totalStorage,
    );
  }
}
