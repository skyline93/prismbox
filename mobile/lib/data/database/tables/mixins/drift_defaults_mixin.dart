// lib/data/database/tables/mixins/drift_defaults_mixin.dart

import 'package:drift/drift.dart';

/// Drift 默认值处理 Mixin
/// 提供通用的默认值处理逻辑
/// 启用 WITHOUT ROWID 以提升查询性能
/// 注意：STRICT 模式需要 SQLite 3.37.0+，iOS 设备可能不支持，因此禁用
mixin DriftDefaultsMixin on Table {
  /// 禁用 STRICT 模式以兼容旧版 SQLite
  /// iOS 设备上的 SQLite 版本可能不支持 STRICT（需要 3.37.0+）
  @override
  bool get isStrict => false;

  /// 启用 WITHOUT ROWID，提升查询性能
  @override
  bool get withoutRowId => true;
}

