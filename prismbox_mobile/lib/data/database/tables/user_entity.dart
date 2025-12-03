// lib/data/database/tables/user_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';

/// 用户实体表
@DataClassName('UserEntityData')
class UserEntity extends Table with DriftDefaultsMixin {
  const UserEntity();

  /// 用户 ID（主键）
  TextColumn get id => text()();
  
  /// 用户名
  TextColumn get name => text()();
  
  /// 邮箱
  TextColumn get email => text().nullable()();
  
  /// 头像 URL
  TextColumn get avatarUrl => text().nullable()();
  
  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();
  
  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

