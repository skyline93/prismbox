# SyncCoordinator 并发控制重构方案

**状态**: 已实施 ✅  
**优先级**: 中  
**创建时间**: 2025-12-11  
**实施时间**: 2025-12-XX  
**模块**: 本地媒体同步模块  
**相关文档**: 
- `doc/issue/并发同步冲突问题分析与修复方案.md`
- `doc/modules/本地媒体同步模块详细设计文档.md`

---

## 实施完成说明

✅ **已使用 AsyncMutex 方案完成重构**

- **实施内容**：已使用 `AsyncMutex` 替换原有的并发控制机制（`_isSyncing` + `_syncLock`）
- **实施位置**：
  - `lib/utils/async_mutex.dart` - AsyncMutex 工具类实现
  - `lib/features/local_sync/services/sync_coordinator.dart` - 使用 AsyncMutex 重构同步协调器
- **实施效果**：
  - ✅ 解决了并发控制中的竞态条件问题
  - ✅ 实现了顺序执行和任务队列支持
  - ✅ 代码更简洁，架构更清晰

---

## 目录

1. [问题回顾](#问题回顾)
2. [三种方案对比](#三种方案对比)
3. [方案C（AsyncMutex）详细设计](#方案casyncmutex详细设计)
4. [实施计划](#实施计划)
5. [测试验证](#测试验证)
6. [风险评估](#风险评估)

---

## 问题回顾

### 当前问题

在 `SyncCoordinator._sync()` 方法中存在空指针异常问题：

```dart
Future<SyncResult> _sync({bool full = false}) async {
  if (_isSyncing) {
    _logger.warning('同步任务正在进行中，等待完成');
    await _syncLock?.future;
    return _currentSyncTask!;  // ❌ 这里会抛出空指针异常
  }
  
  _isSyncing = true;
  final lock = Completer<void>();
  _syncLock = lock;
  
  try {
    _currentSyncTask = _doSync(full: full);
    final result = await _currentSyncTask!;
    return result;
  } finally {
    _isSyncing = false;
    _currentSyncTask = null;  // ❌ 在 finally 中清空，导致等待者访问时为空
    lock.complete();
    _syncLock = null;
  }
}
```

**问题根源**：
- 当第二个同步任务等待第一个同步任务完成时，第一个任务在 `finally` 块中将 `_currentSyncTask` 设置为 `null`
- 等待完成后，执行 `return _currentSyncTask!` 时触发 "Null check operator used on a null value" 错误

### 现有架构设计

当前 `SyncCoordinator` 使用了以下机制：
- ✅ 单例模式（`keepAlive: true`）
- ✅ AsyncMutex 并发控制（已实施，替换了原有的 `_isSyncing` + `_syncLock` 机制）
- ✅ 去重机制（`_lastTriggerTime` + `_triggerDebounce`）
- ✅ 数据新鲜度检查（`_lastSyncedAt` + `_freshnessThreshold`）
- ✅ 并发控制问题已修复（使用 AsyncMutex 保证顺序执行）

---

## 三种方案对比

### 方案A：保存任务引用（临时修复）

**核心思路**：在等待前保存 `_currentSyncTask` 的引用，避免被 `finally` 块清空。

**实现代码**：
```dart
Future<SyncResult> _sync({bool full = false}) async {
  if (_isSyncing) {
    _logger.warning('同步任务正在进行中，等待完成');
    final taskToWait = _currentSyncTask;  // 保存引用
    if (taskToWait != null) {
      await _syncLock?.future;
      return await taskToWait;  // 使用保存的引用
    } else {
      await _syncLock?.future;
      return SyncResult.success();
    }
  }
  // ... 其余代码保持不变
}
```

**优点**：
- ✅ 改动最小（只需3行代码）
- ✅ 立即修复问题
- ✅ 风险低

**缺点**：
- ❌ 仍然是临时修复，架构问题未根本解决
- ❌ 状态管理分散（`_currentSyncTask` 和 `_syncLock` 职责混乱）
- ❌ 难以扩展为任务队列
- ❌ 未来迁移到 Isolate/WorkManager 需要重构

**评分**：
- 短期可行性：⭐⭐⭐⭐⭐
- 长期演进能力：⭐⭐
- 推荐指数：⭐⭐（仅作为临时修复）

---

### 方案B：锁传递结果（架构优化）

**核心思路**：将 `Completer<void>` 改为 `Completer<SyncResult>`，让锁直接传递同步结果。

**实现代码**：
```dart
class SyncCoordinator {
  /// 同步锁（传递同步结果）
  Completer<SyncResult>? _syncLock;
  
  Future<SyncResult> _sync({bool full = false}) async {
    if (_isSyncing) {
      _logger.warning('同步任务正在进行中，等待完成');
      final lock = _syncLock;
      if (lock != null) {
        return await lock.future;  // 锁的结果就是同步结果
      } else {
        return SyncResult.success();
      }
    }
    
    _isSyncing = true;
    final lock = Completer<SyncResult>();  // 改为传递结果
    _syncLock = lock;
    
    try {
      _currentSyncTask = _doSync(full: full);
      final result = await _currentSyncTask!;
      lock.complete(result);  // 完成锁并传递结果
      return result;
    } catch (e) {
      final errorResult = SyncResult.failure(e.toString());
      lock.complete(errorResult);  // 即使异常也要完成锁
      rethrow;
    } finally {
      _isSyncing = false;
      _currentSyncTask = null;
      _syncLock = null;
    }
  }
}
```

**优点**：
- ✅ 架构更清晰（锁负责传递结果）
- ✅ 职责明确（消除 `_currentSyncTask` 和 `_syncLock` 的职责混乱）
- ✅ 改动适中（主要是类型修改）
- ✅ 符合"锁传递结果"的设计模式

**缺点**：
- ❌ 仍然是单任务模式，难以扩展为队列
- ❌ 取消机制仍需额外处理
- ❌ 未来迁移到 Isolate/WorkManager 需要重构

**评分**：
- 短期可行性：⭐⭐⭐⭐
- 长期演进能力：⭐⭐⭐
- 推荐指数：⭐⭐⭐（架构优化，但仍有局限性）

---

### 方案C：AsyncMutex 模式（成熟架构）

**核心思路**：使用 `AsyncMutex` 模式，实现顺序执行和任务队列支持。

**AsyncMutex 实现**（参考 Immich）：
```dart
/// Async mutex to guarantee actions are performed sequentially and do not interleave
class AsyncMutex {
  Future _running = Future.value(null);
  int _enqueued = 0;

  int get enqueued => _enqueued;

  /// Execute [operation] exclusively, after any currently running operations.
  /// Returns a [Future] with the result of the [operation].
  Future<T> run<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _enqueued++;
    _running.whenComplete(() {
      _enqueued--;
      completer.complete(Future<T>.sync(operation));
    });
    return _running = completer.future;
  }
}
```

**SyncCoordinator 重构**：
```dart
class SyncCoordinator {
  final AsyncMutex _syncMutex = AsyncMutex();
  
  Future<SyncResult> _sync({bool full = false}) async {
    return await _syncMutex.run(() => _doSync(full: full));
  }
}
```

**优点**：
- ✅ **成熟的设计模式**（被 Immich 等成熟项目使用）
- ✅ **天然支持任务队列**（顺序执行）
- ✅ **易于扩展**（取消、优先级、重试等）
- ✅ **易于迁移到 Isolate/WorkManager**
- ✅ **代码简洁清晰**
- ✅ **技术债务最低**

**缺点**：
- ❌ 需要一定的重构工作
- ❌ 需要添加 AsyncMutex 工具类

**评分**：
- 短期可行性：⭐⭐⭐
- 长期演进能力：⭐⭐⭐⭐⭐
- 推荐指数：⭐⭐⭐⭐⭐（最佳长期方案）

---

## 方案C（AsyncMutex）详细设计

### 1. 架构设计

#### 1.1 核心组件

```
SyncCoordinator
├── AsyncMutex _syncMutex          // 并发控制
├── CancelToken? _cancelToken      // 取消机制（可选）
├── StreamController _statusController  // 状态流
└── StreamController _dataSourceSwitchController  // 数据源切换流
```

#### 1.2 执行流程

```
调用 sync() / _checkAndSync()
    ↓
AsyncMutex.run()
    ↓
如果已有任务在执行 → 等待
    ↓
执行 _doSync()
    ↓
更新状态、通知数据源切换
    ↓
返回结果
```

### 2. 详细实现

#### 2.1 AsyncMutex 工具类

**文件**: `lib/utils/async_mutex.dart`

```dart
import 'dart:async';

/// Async mutex to guarantee actions are performed sequentially and do not interleave
/// 
/// 确保操作顺序执行，不会交错
/// 参考: Immich Mobile (immich_mobile/lib/utils/async_mutex.dart)
class AsyncMutex {
  /// 当前正在运行的任务
  Future _running = Future.value(null);
  
  /// 队列中的任务数量（包括正在运行的）
  int _enqueued = 0;

  /// 获取队列中的任务数量
  int get enqueued => _enqueued;

  /// 执行操作（独占执行）
  /// 
  /// 如果有操作正在运行，会等待完成后执行
  /// 
  /// [operation] 要执行的操作
  /// 返回操作的结果
  Future<T> run<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _enqueued++;
    
    // 当前任务完成后，执行新任务
    _running.whenComplete(() {
      _enqueued--;
      completer.complete(Future<T>.sync(operation));
    });
    
    // 更新运行链
    return _running = completer.future;
  }
}
```

#### 2.2 SyncCoordinator 重构

**文件**: `lib/features/local_sync/services/sync_coordinator.dart`

```dart
import 'package:prismbox/utils/async_mutex.dart';

class SyncCoordinator {
  final LocalSyncService _syncService;
  final AppDatabase _database;
  final Logger _logger = Logger('SyncCoordinator');
  
  /// 同步状态流控制器
  final _statusController = StreamController<SyncStatusInfo>.broadcast();
  
  /// 数据源切换通知流控制器
  final _dataSourceSwitchController = StreamController<bool>.broadcast();
  
  /// 同步互斥锁（确保顺序执行）
  final AsyncMutex _syncMutex = AsyncMutex();
  
  /// 取消令牌（用于手动取消）
  CancelToken? _cancelToken;
  
  /// 最后同步时间
  DateTime? _lastSyncedAt;
  
  /// 最后触发时间（用于去重）
  DateTime? _lastTriggerTime;
  
  /// 数据新鲜度阈值（1小时）
  static const Duration _freshnessThreshold = Duration(hours: 1);
  
  /// 启动延迟（2秒）
  static const Duration _startDelay = Duration(seconds: 2);
  
  /// 触发防抖时间（3秒）
  static const Duration _triggerDebounce = Duration(seconds: 3);

  // ... 构造函数和 getter 保持不变 ...

  /// 手动触发同步
  /// 
  /// [full] 是否全量同步
  Future<SyncResult> syncManually({bool full = false}) async {
    // 如果有任务正在运行，取消它
    if (_syncMutex.enqueued > 0) {
      _logger.warning('同步任务正在进行中，取消当前任务');
      cancel();
      // 等待当前任务完成（被取消）
      await _syncMutex._running;
    }

    return await _sync(full: full);
  }

  /// 统一的同步触发入口（带去重）
  Future<void> _checkAndSync({bool force = false}) async {
    // 去重：如果最近3秒内已触发，跳过
    if (!force && _lastTriggerTime != null) {
      final timeSinceLastTrigger = DateTime.now().difference(_lastTriggerTime!);
      if (timeSinceLastTrigger < _triggerDebounce) {
        _logger.info('最近已触发同步，跳过（去重）');
        return;
      }
    }
    
    _lastTriggerTime = DateTime.now();
    
    try {
      // 检查数据新鲜度
      final isFresh = _lastSyncedAt != null &&
          DateTime.now().difference(_lastSyncedAt!) < _freshnessThreshold;

      if (isFresh) {
        _logger.info('数据新鲜，跳过同步');
        return;
      }

      // 执行增量同步
      await _sync(full: false);
    } catch (e) {
      _logger.warning('自动同步失败', e);
    }
  }

  /// 执行同步（使用 AsyncMutex 保证顺序执行）
  Future<SyncResult> _sync({bool full = false}) async {
    return await _syncMutex.run(() async {
      try {
        return await _doSync(full: full);
      } catch (e, stackTrace) {
        _logger.severe('同步执行异常', e, stackTrace);
        return SyncResult.failure(e.toString());
      }
    });
  }

  /// 执行同步任务
  Future<SyncResult> _doSync({bool full = false}) async {
    try {
      // 创建取消令牌
      _cancelToken = CancelToken();
      
      _updateStatus(
        SyncStatus.syncing,
        current: 0,
        total: 0,
      );
      
      final result = await _syncService.syncLocal(
        full: full,
        onProgress: (current, total) {
          _updateStatus(
            SyncStatus.syncing,
            current: current,
            total: total,
          );
        },
      );

      if (result.success) {
        _lastSyncedAt = DateTime.now();
        _updateStatus(
          SyncStatus.success,
          current: result.total,
          total: result.total,
          lastSyncedAt: _lastSyncedAt,
        );
        _logger.info('同步成功: $result');
        
        // 同步成功后，检查是否需要切换到数据库数据源
        await _checkAndSwitchDataSource();
      } else {
        _updateStatus(
          SyncStatus.error,
          current: 0,
          total: 0,
          error: result.error,
        );
        _logger.warning('同步失败: ${result.error}');
      }

      return result;
    } catch (e, stackTrace) {
      _logger.severe('同步异常', e, stackTrace);
      _updateStatus(
        SyncStatus.error,
        current: 0,
        total: 0,
        error: e.toString(),
      );
      return SyncResult.failure(e.toString());
    } finally {
      _cancelToken = null;
    }
  }

  /// 取消同步
  void cancel() {
    _cancelToken?.cancel();
    _updateStatus(SyncStatus.idle);
  }

  // ... 其他方法保持不变 ...
}

/// 取消令牌
class CancelToken {
  bool _isCanceled = false;

  bool get isCanceled => _isCanceled;

  void cancel() {
    _isCanceled = true;
  }
}
```

### 3. 未来扩展设计

#### 3.1 优先级队列（未来扩展）

```dart
/// 同步优先级
enum SyncPriority {
  low,      // 低优先级（后台同步）
  normal,   // 普通优先级（自动同步）
  high,     // 高优先级（手动同步）
}

/// 支持优先级的 AsyncMutex
class PriorityAsyncMutex {
  final _highPriorityQueue = <_Task>[];
  final _normalPriorityQueue = <_Task>[];
  final _lowPriorityQueue = <_Task>[];
  bool _isRunning = false;

  Future<T> run<T>(
    Future<T> Function() operation, {
    SyncPriority priority = SyncPriority.normal,
  }) async {
    // ... 实现优先级调度
  }
}
```

#### 3.2 重试机制（未来扩展）

```dart
Future<SyncResult> _sync({
  bool full = false,
  int maxRetries = 3,
  Duration retryDelay = const Duration(seconds: 5),
}) async {
  return await _syncMutex.run(() async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await _doSync(full: full);
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          return SyncResult.failure('重试 $maxRetries 次后仍然失败: $e');
        }
        _logger.warning('同步失败，${retryDelay.inSeconds}秒后重试 (${attempts}/$maxRetries)', e);
        await Future.delayed(retryDelay);
      }
    }
    return SyncResult.failure('未知错误');
  });
}
```

#### 3.3 Isolate 集成（未来扩展）

```dart
Future<SyncResult> _sync({bool full = false}) async {
  return await _syncMutex.run(() async {
    // 在 Isolate 中执行同步
    return await compute(_doSyncInIsolate, {
      'full': full,
      'databasePath': _database.path,
    });
  });
}
```

#### 3.4 WorkManager 集成（未来扩展）

```dart
void registerPeriodicSync() {
  Workmanager.registerPeriodicTask(
    'localMediaSync',
    'syncLocalMedia',
    frequency: Duration(hours: 4),
    constraints: Constraints(
      networkType: NetworkType.unmetered, // Wi-Fi
      requiresCharging: false,
    ),
  );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    if (task == 'syncLocalMedia') {
      // 在后台执行同步
      final coordinator = await _createCoordinatorInBackground();
      await coordinator._sync(full: false);
      return Future.value(true);
    }
    return Future.value(false);
  });
}
```

---

## 实施计划

### 阶段1：基础实现（1-2天）

**目标**：实现 AsyncMutex 并修复并发问题

1. **创建 AsyncMutex 工具类**
   - 文件：`lib/utils/async_mutex.dart`
   - 实现基础功能
   - 添加单元测试

2. **重构 SyncCoordinator**
   - 移除 `_isSyncing`、`_syncLock`、`_currentSyncTask`
   - 使用 `AsyncMutex` 替换
   - 简化 `_sync()` 方法

3. **测试验证**
   - 并发测试
   - 取消机制测试
   - 集成测试

### 阶段2：取消机制优化（可选，1天）

**目标**：改进取消机制

1. **改进 CancelToken**
   - 在 `LocalSyncService` 中传递 `CancelToken`
   - 实现优雅取消

2. **测试验证**
   - 取消测试
   - 取消后重新启动测试

### 阶段3：文档更新（0.5天）

**目标**：更新相关文档

1. 更新架构文档
2. 更新 API 文档
3. 添加使用示例

---

## 测试验证

### 测试场景

#### 场景1：并发同步控制

**步骤**：
1. 启动应用，触发自动同步
2. 在同步进行中，快速切换应用前后台
3. 观察日志

**预期结果**：
- 只有一个同步任务执行
- 后续任务等待当前任务完成
- 没有并发冲突错误
- 没有空指针异常

#### 场景2：任务队列验证

**步骤**：
1. 快速连续触发多次同步
2. 观察日志和队列状态

**预期结果**：
- 任务按顺序执行
- `AsyncMutex.enqueued` 正确计数
- 没有任务丢失

#### 场景3：取消机制验证

**步骤**：
1. 触发同步
2. 在同步进行中调用 `cancel()`
3. 再次触发同步

**预期结果**：
- 取消成功
- 后续同步正常执行

---

## 风险评估

### 低风险

- **AsyncMutex 实现**：成熟模式，参考 Immich 实现
- **代码简化**：移除复杂的锁机制，代码更清晰

### 中风险

- **取消机制**：需要确保 `CancelToken` 正确传递和使用
- **状态管理**：移除 `_currentSyncTask` 后，需要确保状态流正常工作

### 缓解措施

1. **充分测试**：覆盖所有并发场景
2. **渐进式迁移**：可以先保留旧代码，逐步迁移
3. **回滚方案**：如果出现问题，可以快速回滚到方案B

---

## 迁移路径

### 推荐迁移策略

考虑到当前问题的紧急性和长期架构演进，建议采用**分阶段迁移**：

1. **立即修复**（方案B）：
   - 快速修复空指针问题
   - 架构优化，职责清晰
   - 稳定运行1-2周

2. **架构重构**（方案C）：
   - 在下一个迭代周期实施
   - 有充分时间设计和测试
   - 为未来扩展打下基础

### 迁移检查清单

- [x] AsyncMutex 实现完成 ✅
- [x] SyncCoordinator 重构完成 ✅
- [ ] 单元测试通过
- [ ] 集成测试通过
- [ ] 并发场景测试通过
- [ ] 取消机制测试通过
- [ ] 性能测试通过
- [x] 文档更新完成 ✅
- [ ] 代码审查通过

---

## 总结

### 方案对比总结

| 方案 | 短期可行性 | 长期演进能力 | 技术债务 | 推荐指数 |
|------|-----------|------------|---------|---------|
| 方案A（保存引用） | ⭐⭐⭐⭐⭐ | ⭐⭐ | 高 | ⭐⭐ |
| 方案B（锁传递结果） | ⭐⭐⭐⭐ | ⭐⭐⭐ | 中 | ⭐⭐⭐ |
| 方案C（AsyncMutex） | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 低 | ⭐⭐⭐⭐⭐ |

### 最终推荐

**长期推荐**：方案C（AsyncMutex）
- ✅ 最符合未来架构演进方向
- ✅ 技术债务最低
- ✅ 易于扩展和维护
- ✅ 与行业最佳实践一致

**短期策略**：方案B（锁传递结果）
- ✅ 快速修复问题
- ✅ 架构优化，职责清晰
- ✅ 稳定运行后再迁移到方案C

---

**最后更新**: 2025-12-11

