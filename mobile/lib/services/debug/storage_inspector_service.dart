// lib/services/debug/storage_inspector_service.dart

import 'package:flutter/foundation.dart';
import 'package:storage_inspector/storage_inspector.dart';
import 'package:drift_local_storage_inspector/drift_local_storage_inspector.dart';
import 'package:prismbox/data/database/app_database.dart';

/// Storage Inspector 服务
/// 仅在调试模式下启用，用于可视化查看和调试本地数据库
class StorageInspectorService {
  static StorageServerDriver? _driver;
  static bool _isInitialized = false;

  /// 初始化 Storage Inspector
  /// 仅在调试模式下启用
  static Future<void> initialize(AppDatabase database) async {
    if (!kDebugMode) {
      // 非调试模式下不启用
      return;
    }

    if (_isInitialized) {
      // 已经初始化，避免重复初始化
      return;
    }

    try {
      // 创建 Storage Server Driver
      _driver = StorageServerDriver(
        bundleId: 'com.u163.glf9832.prismbox', // 应用 ID
        port: 0, // 0 表示自动选择空闲端口
      );

      // 添加 Drift 数据库服务器
      final driftServer = DriftSQLDatabaseServer(
        id: 'prismbox_database',
        name: 'PrismBox Database', // 显示名称
        database: database,
      );
      _driver!.addSQLServer(driftServer);

      // 启动服务器
      await _driver!.start();

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ Storage Inspector 已启动');
        debugPrint('📊 数据库调试工具已就绪，可在 IDE 中查看数据库');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Storage Inspector 启动失败: $e');
        debugPrint('堆栈跟踪: $stackTrace');
      }
      // 启动失败不影响应用运行
    }
  }

  /// 关闭 Storage Inspector
  static Future<void> shutdown() async {
    if (!kDebugMode || _driver == null) {
      return;
    }

    try {
      await _driver!.stop();
      _driver = null;
      _isInitialized = false;

      if (kDebugMode) {
        debugPrint('Storage Inspector 已关闭');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('关闭 Storage Inspector 时出错: $e');
      }
    }
  }

  /// 检查是否已初始化
  static bool get isInitialized => _isInitialized;
}

