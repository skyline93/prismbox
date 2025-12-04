import 'dart:async';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_repository.dart';
import 'package:logging/logging.dart';

/// Store服务 - 应用级键值存储服务
/// 提供内存缓存和持久化存储的双层架构
class StoreService {
  static final StoreService _instance = StoreService._internal();
  factory StoreService() => _instance;
  StoreService._internal();

  final Logger _log = Logger('StoreService');
  final Map<int, Object?> _cache = {};
  StoreRepository? _repository;
  StreamSubscription? _updateSubscription;
  bool _initialized = false;

  /// 初始化Store服务
  Future<void> init(StoreRepository repository) async {
    if (_initialized) {
      _log.warning('StoreService already initialized');
      return;
    }

    _repository = repository;
    
    // 从持久化存储加载所有数据到内存缓存
    final allValues = await _repository!.getAll();
    for (final value in allValues) {
      _cache[value.key] = value.value;
    }

    // 监听持久化存储的变更
    _updateSubscription = _repository!.watchAll().listen((events) {
      for (final event in events) {
        _cache[event.key] = event.value;
      }
    });

    _initialized = true;
    _log.info('StoreService initialized with ${_cache.length} items');
  }

  /// 释放资源
  Future<void> dispose() async {
    await _updateSubscription?.cancel();
    _cache.clear();
    _initialized = false;
    _log.info('StoreService disposed');
  }

  /// 尝试获取值，如果不存在返回null
  T? tryGet<T>(StoreKey<T> key) {
    final value = _cache[key.id];
    if (value == null) return null;
    return value as T;
  }

  /// 获取值，如果不存在返回默认值或抛出异常
  T get<T>(StoreKey<T> key, [T? defaultValue]) {
    final value = tryGet(key);
    if (value != null) return value;
    if (defaultValue != null) return defaultValue;
    throw StoreKeyNotFoundException(key);
  }

  /// 存储值
  Future<void> put<T>(StoreKey<T> key, T value) async {
    if (!_initialized) {
      throw StateError('StoreService not initialized. Call init() first.');
    }

    // 如果值没有变化，跳过写入
    if (_cache[key.id] == value) return;

    await _repository!.put(key.id, value);
    _cache[key.id] = value;
  }

  /// 删除值
  Future<void> delete<T>(StoreKey<T> key) async {
    if (!_initialized) {
      throw StateError('StoreService not initialized. Call init() first.');
    }

    await _repository!.delete(key.id);
    _cache.remove(key.id);
  }

  /// 监听值的变化
  Stream<T?> watch<T>(StoreKey<T> key) {
    if (!_initialized) {
      throw StateError('StoreService not initialized. Call init() first.');
    }
    return _repository!.watch(key.id).map((value) => value as T?);
  }

  /// 清空所有值
  Future<void> clear() async {
    if (!_initialized) {
      throw StateError('StoreService not initialized. Call init() first.');
    }

    await _repository!.deleteAll();
    _cache.clear();
  }

  /// 检查是否已初始化
  bool get isInitialized => _initialized;
}

/// Store键未找到异常
class StoreKeyNotFoundException implements Exception {
  final StoreKey key;
  const StoreKeyNotFoundException(this.key);

  @override
  String toString() => 'StoreKeyNotFoundException: Key <${key.name}> not found';
}

