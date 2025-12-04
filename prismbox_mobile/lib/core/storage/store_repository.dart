import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';

/// Store值数据类
class StoreValue {
  final int key;
  final Object? value;

  StoreValue({required this.key, required this.value});
}

/// Store仓库接口
abstract class StoreRepository {
  /// 获取所有值
  Future<List<StoreValue>> getAll();

  /// 获取单个值
  Future<Object?> get(int key);

  /// 存储值
  Future<void> put(int key, Object? value);

  /// 删除值
  Future<void> delete(int key);

  /// 删除所有值
  Future<void> deleteAll();

  /// 监听所有变更
  Stream<List<StoreValue>> watchAll();

  /// 监听单个键的变更
  Stream<Object?> watch(int key);
}

/// 基于Drift数据库的Store仓库实现
class DriftStoreRepository implements StoreRepository {
  final AppDatabase _database;

  DriftStoreRepository(this._database);

  @override
  Future<List<StoreValue>> getAll() async {
    final rows = await (_database.select(_database.storeEntity)
          ..orderBy([(t) => OrderingTerm(expression: t.key)]))
        .get();

    return rows.map((row) {
      Object? value;
      if (row.value != null) {
        try {
          // 尝试解析JSON
          final decoded = jsonDecode(row.value!);
          value = decoded;
        } catch (e) {
          // 如果不是JSON，直接使用字符串
          value = row.value;
        }
      }
      return StoreValue(key: row.key, value: value);
    }).toList();
  }

  @override
  Future<Object?> get(int key) async {
    final row = await (_database.select(_database.storeEntity)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();

    if (row == null || row.value == null) {
      return null;
    }

    try {
      // 尝试解析JSON
      return jsonDecode(row.value!);
    } catch (e) {
      // 如果不是JSON，直接返回字符串
      return row.value;
    }
  }

  @override
  Future<void> put(int key, Object? value) async {
    String? jsonValue;
    if (value != null) {
      // 将值转换为JSON字符串
      jsonValue = jsonEncode(value);
    }

    await _database.into(_database.storeEntity).insertOnConflictUpdate(
          StoreEntityCompanion(
            key: Value(key),
            value: Value(jsonValue),
          ),
        );
  }

  @override
  Future<void> delete(int key) async {
    await (_database.delete(_database.storeEntity)
          ..where((t) => t.key.equals(key)))
        .go();
  }

  @override
  Future<void> deleteAll() async {
    await _database.delete(_database.storeEntity).go();
  }

  @override
  Stream<List<StoreValue>> watchAll() {
    return (_database.select(_database.storeEntity)
          ..orderBy([(t) => OrderingTerm(expression: t.key)]))
        .watch()
        .map((rows) {
      return rows.map((row) {
        Object? value;
        if (row.value != null) {
          try {
            final decoded = jsonDecode(row.value!);
            value = decoded;
          } catch (e) {
            value = row.value;
          }
        }
        return StoreValue(key: row.key, value: value);
      }).toList();
    });
  }

  @override
  Stream<Object?> watch(int key) {
    return (_database.select(_database.storeEntity)
          ..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) {
      if (row == null || row.value == null) {
        return null;
      }

      try {
        return jsonDecode(row.value!);
      } catch (e) {
        return row.value;
      }
    });
  }
}

/// 基于SharedPreferences的Store仓库实现（临时方案）
class SharedPreferencesStoreRepository implements StoreRepository {
  final Map<int, Object?> _storage = {};
  final Map<int, StreamController<Object?>> _controllers = {};

  @override
  Future<List<StoreValue>> getAll() async {
    return _storage.entries
        .map((e) => StoreValue(key: e.key, value: e.value))
        .toList();
  }

  @override
  Future<Object?> get(int key) async {
    return _storage[key];
  }

  @override
  Future<void> put(int key, Object? value) async {
    _storage[key] = value;
    _controllers[key]?.add(value);
  }

  @override
  Future<void> delete(int key) async {
    _storage.remove(key);
    _controllers[key]?.add(null);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
    for (final controller in _controllers.values) {
      controller.add(null);
    }
  }

  @override
  Stream<List<StoreValue>> watchAll() {
    // 简化实现：返回当前所有值
    return Stream.fromFuture(getAll());
  }

  @override
  Stream<Object?> watch(int key) {
    _controllers[key] ??= StreamController<Object?>.broadcast();
    return _controllers[key]!.stream;
  }
}

