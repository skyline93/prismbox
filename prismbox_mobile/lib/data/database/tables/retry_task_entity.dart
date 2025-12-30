// lib/data/database/tables/retry_task_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';

/// 重试任务类型枚举（数据库存储用整数）
enum RetryTaskTypeDb {
  addAssets(0),
  removeAssets(1),
  migrateToPrivateSpace(2),
  migrateFromPrivateSpace(3);

  final int value;
  const RetryTaskTypeDb(this.value);

  static RetryTaskTypeDb fromInt(int value) {
    return RetryTaskTypeDb.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RetryTaskTypeDb.addAssets,
    );
  }
}

/// 重试任务实体表
/// 存储需要重试的任务信息
@DataClassName('RetryTaskEntityData')
class RetryTaskEntity extends Table with DriftDefaultsMixin {
  const RetryTaskEntity();

  /// 主键（任务ID）
  TextColumn get id => text()();

  /// 任务类型
  IntColumn get taskType => integer()();

  /// 相册ID
  TextColumn get albumId => text()();

  /// 资产ID列表（JSON格式存储）
  TextColumn get assetIds => text()();

  /// 额外数据（JSON格式存储，可选）
  TextColumn get extraData => text().nullable()();

  /// 重试次数
  IntColumn get retryCount => integer()
      .withDefault(const Constant(0))();

  /// 最后重试时间
  DateTimeColumn get lastRetryAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

