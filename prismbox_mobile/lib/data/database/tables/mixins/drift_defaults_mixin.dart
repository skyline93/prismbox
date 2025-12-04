// lib/data/database/tables/mixins/drift_defaults_mixin.dart

import 'package:drift/drift.dart';

/// Drift 默认值处理 Mixin
/// 提供通用的默认值处理逻辑
/// 启用 STRICT 模式和 WITHOUT ROWID 以提升性能和类型安全
mixin DriftDefaultsMixin on Table {
  /// 启用 STRICT 模式，确保类型安全
  @override
  bool get isStrict => true;

  /// 启用 WITHOUT ROWID，提升查询性能
  @override
  bool get withoutRowId => true;
}

