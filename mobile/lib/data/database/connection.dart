// lib/data/database/connection.dart

import 'dart:io';
import 'dart:ui';
import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/exceptions/database_exception.dart';

/// 数据库连接管理
/// 支持跨 Isolate 共享连接
class DatabaseConnection {
  static AppDatabase? _database;
  static const String _isolatePortName = 'prismbox_db_isolate_port';
  
  /// 初始化数据库 Isolate
  /// 必须在应用启动时调用，通常在 main() 函数中
  static Future<void> initializeDatabaseIsolate() async {
    if (IsolateNameServer.lookupPortByName(_isolatePortName) != null) {
      // Isolate 已经初始化
      return;
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'prismbox.db');

    // 创建数据库连接函数
    LazyDatabase openConnection() {
      return LazyDatabase(() async {
        final file = File(dbPath);
        return NativeDatabase.createInBackground(
          file,
          setup: (database) {
            // SQLite PRAGMA 设置
            database.execute('PRAGMA foreign_keys = ON');
            database.execute('PRAGMA journal_mode = WAL');
            database.execute('PRAGMA synchronous = NORMAL');
            database.execute('PRAGMA busy_timeout = 30000');
          },
        );
      });
    }

    // 在独立的 Isolate 中启动数据库
    final driftIsolate = await DriftIsolate.spawn(openConnection);

    // 注册端口，供其他 Isolate 连接
    final success = IsolateNameServer.registerPortWithName(
      driftIsolate.connectPort,
      _isolatePortName,
    );

    if (!success) {
      driftIsolate.shutdownAll();
      throw DatabaseException(
        type: DatabaseErrorType.connectionFailed,
        message: '无法注册数据库 Isolate 端口。可能已有同名端口被注册。',
        originalError: null,
      );
    }
  }
  
  /// 获取数据库实例（单例模式）
  /// 如果 Isolate 已初始化，会连接到 Isolate 中的数据库
  /// 否则会在当前 Isolate 中创建数据库连接
  static Future<AppDatabase> getInstance() async {
    if (_database != null) {
      return _database!;
    }

    // 尝试连接到已初始化的 Isolate
    final port = IsolateNameServer.lookupPortByName(_isolatePortName);
    
    if (port != null) {
      // 连接到 Isolate 中的数据库
      try {
        final isolate = DriftIsolate.fromConnectPort(port);
        final connection = await isolate.connect();
        _database = AppDatabase(connection);
        return _database!;
      } catch (e, stackTrace) {
        throw DatabaseException(
          type: DatabaseErrorType.connectionFailed,
          message: '连接数据库 Isolate 失败: $e\n堆栈跟踪: $stackTrace',
          originalError: e,
        );
      }
    } else {
      // Isolate 未初始化，在当前 Isolate 中创建连接（用于测试或单 Isolate 场景）
      _database = AppDatabase(_openConnectionInCurrentIsolate());
      return _database!;
    }
  }
  
  /// 关闭数据库连接
  /// 
  /// 如果关闭失败，会抛出 [DatabaseException]
  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      _database = null;
      try {
        // AppDatabase 继承自 GeneratedDatabase，有 close() 方法
        await db.close();
      } catch (e, stackTrace) {
        // 关闭失败时抛出异常，而不是静默忽略
        throw DatabaseException(
          type: DatabaseErrorType.connectionFailed,
          message: '关闭数据库连接失败: $e\n堆栈跟踪: $stackTrace',
          originalError: e,
        );
      }
    }
  }
  
  /// 在当前 Isolate 中打开数据库连接（用于测试或单 Isolate 场景）
  static LazyDatabase _openConnectionInCurrentIsolate() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'prismbox.db'));
      
      return NativeDatabase.createInBackground(
        file,
        setup: (database) {
          // SQLite PRAGMA 设置
          database.execute('PRAGMA foreign_keys = ON');
          database.execute('PRAGMA journal_mode = WAL');
          database.execute('PRAGMA synchronous = NORMAL');
          database.execute('PRAGMA busy_timeout = 30000');
        },
      );
    });
  }
}

