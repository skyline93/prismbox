// lib/data/database/daos/user_dao.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/tables/user_entity.dart';

part 'user_dao.g.dart';

/// 用户数据访问对象
/// 提供用户的查询和操作接口
@DriftAccessor(tables: [UserEntity])
class UserDao extends DatabaseAccessor<AppDatabase>
    with _$UserDaoMixin {
  UserDao(AppDatabase db) : super(db);

  /// 获取所有用户
  Future<List<UserEntityData>> getAllUsers() {
    return select(userEntity).get();
  }

  /// 根据 ID 获取用户
  Future<UserEntityData?> getUserById(String id) {
    return (select(userEntity)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 根据邮箱获取用户
  Future<UserEntityData?> getUserByEmail(String email) {
    return (select(userEntity)
          ..where((t) => t.email.equals(email)))
        .getSingleOrNull();
  }

  /// 插入用户
  Future<void> insertUser(UserEntityData user) {
    return into(userEntity).insert(user);
  }

  /// 批量插入用户
  Future<void> insertUsers(List<UserEntityData> users) {
    return batch((batch) {
      batch.insertAll(userEntity, users);
    });
  }

  /// 更新用户
  Future<bool> updateUser(UserEntityData user) {
    return update(userEntity).replace(user);
  }

  /// 删除用户
  Future<bool> deleteUser(String id) async {
    final count = await (delete(userEntity)
          ..where((t) => t.id.equals(id)))
        .go();
    return count > 0;
  }

  /// 流式查询：监听用户变化
  Stream<List<UserEntityData>> watchUsers() {
    return select(userEntity).watch();
  }

  /// 根据 ID 监听单个用户
  Stream<UserEntityData?> watchUserById(String id) {
    return (select(userEntity)
          ..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }
}

