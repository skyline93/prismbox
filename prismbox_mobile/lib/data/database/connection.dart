// lib/data/database/connection.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:prismbox/data/database/app_database.dart';

/// 数据库连接管理
/// 支持跨 Isolate 共享连接
class DatabaseConnection {
  static AppDatabase? _database;
  
  /// 获取数据库实例（单例模式）
  static Future<AppDatabase> getInstance() async {
    if (_database == null) {
      _database = AppDatabase(_openConnection());
    }
    return _database!;
  }
  
  /// 关闭数据库连接
  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }
  
  /// 打开数据库连接
  static LazyDatabase _openConnection() {
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
        shareAcrossIsolates: true, // 关键：支持跨 Isolate
      );
    });
  }
}

