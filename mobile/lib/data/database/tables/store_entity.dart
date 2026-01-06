import 'package:drift/drift.dart';

/// Store表定义
/// 用于存储应用设置和键值对数据
class StoreEntity extends Table {
  /// 键ID（对应StoreKey.id）
  IntColumn get key => integer()();

  /// 值（JSON字符串）
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

