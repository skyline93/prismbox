# 性能优化 Issue 清单

本文档记录了本地存储模块的性能优化计划和已完成的优化工作。

## Issue 优先级说明

- 🔴 **P0 - 紧急**：立即优化，严重影响性能和用户体验
- 🟡 **P1 - 高优先级**：近期优化，影响核心功能性能
- 🟡 **P2 - 中优先级**：中期优化，影响特定场景性能
- 🟢 **P3 - 低优先级**：可暂缓，影响较小或只在特定条件下出现

---

## 🔴 P0 - 存储池大小更新锁竞争优化

### Issue #001: 使用原子操作替代锁保护存储池大小更新

**状态**: 🔴 待优化  
**优先级**: P0 - 紧急  
**创建时间**: 2025-11-05  
**预计工作量**: 1-2 小时

### 问题描述

当前 `StoragePool.AddSize()` 和 `SubtractSize()` 方法使用 `sync.Mutex` 保护 `CurrentSize` 字段的更新。在高并发场景下，每次文件上传/删除操作都会触发存储池大小的更新，导致频繁的锁竞争。

**影响**:
- ✅ **发生频率**: 极高 - 每次文件操作都触发
- ✅ **业务影响**: 直接影响文件上传/删除性能
- ✅ **性能影响**: 高并发下成为性能瓶颈
- ✅ **用户体验**: 上传响应时间变慢

### 当前实现

```go
// pool_manager.go:206-211
func (sp *StoragePool) AddSize(size int64) {
    sp.mu.Lock()
    defer sp.mu.Unlock()
    sp.CurrentSize += size
}
```

### 优化方案

使用 `sync/atomic` 包的原子操作替代锁，实现无锁更新：

```go
import "sync/atomic"

type StoragePool struct {
    CurrentSize int64  // 直接使用 int64，无需锁保护
    // ... 其他字段
}

func (sp *StoragePool) AddSize(size int64) {
    atomic.AddInt64(&sp.CurrentSize, size)
}

func (sp *StoragePool) SubtractSize(size int64) {
    atomic.AddInt64(&sp.CurrentSize, -size)
    // 处理负数情况
    if atomic.LoadInt64(&sp.CurrentSize) < 0 {
        atomic.StoreInt64(&sp.CurrentSize, 0)
    }
}
```

### 预期收益

- **性能提升**: 消除锁竞争，提升 30-50% 的并发写入性能
- **延迟降低**: 减少文件操作延迟 10-20ms
- **CPU 占用**: 降低锁相关的 CPU 开销

### 风险评估

- **风险等级**: 低
- **风险说明**: 原子操作是标准库提供，稳定可靠；需要处理负数边界情况
- **测试要求**: 
  - 并发写入/删除测试
  - 边界值测试（负数、溢出）

### 验收标准

- [ ] 所有存储池大小更新使用原子操作
- [ ] 通过并发压力测试（1000+ 并发）
- [ ] 性能测试显示吞吐量提升 30%+
- [ ] 无数据竞争或死锁

---

## 🟡 P1 - 临时文件管理器串行化优化

### Issue #002: 按 category 分片锁优化临时文件创建

**状态**: 🟡 待优化  
**优先级**: P1 - 高优先级  
**创建时间**: 2025-11-05  
**预计工作量**: 1-2 天

### 问题描述

当前 `TempFileManager.CreateTempFile()` 方法使用全局互斥锁，所有临时文件的创建操作都串行化执行。在高并发上传场景下，这成为显著的性能瓶颈。

**影响**:
- ✅ **发生频率**: 高 - 每次上传文件（key 格式不正确时）都会创建临时文件
- ✅ **业务影响**: 影响文件上传流程的核心路径
- ✅ **性能影响**: 高并发上传时串行化明显
- ✅ **用户体验**: 上传操作排队等待

### 当前实现

```go
// temp_manager.go:54-92
func (tm *TempFileManager) CreateTempFile(prefix string, category string) (*os.File, error) {
    tm.mu.Lock()  // 全局锁，所有操作串行化
    defer tm.mu.Unlock()
    // ...
}
```

### 优化方案

按 category 分片锁，减少锁竞争：

```go
type TempFileManager struct {
    baseDir         string
    categoryLocks  sync.Map  // map[string]*sync.Mutex
    // ... 其他字段
}

func (tm *TempFileManager) getCategoryLock(category string) *sync.Mutex {
    lock, _ := tm.categoryLocks.LoadOrStore(category, &sync.Mutex{})
    return lock.(*sync.Mutex)
}

func (tm *TempFileManager) CreateTempFile(prefix string, category string) (*os.File, error) {
    lock := tm.getCategoryLock(category)  // 获取 category 专用锁
    lock.Lock()
    defer lock.Unlock()
    // ...
}
```

### 预期收益

- **性能提升**: 不同 category 的临时文件创建可以并发执行
- **并发能力**: 提升 2-5 倍并发上传能力（取决于 category 数量）
- **延迟降低**: 减少上传等待时间 50-100ms

### 风险评估

- **风险等级**: 中等
- **风险说明**: 需要测试不同 category 的并发安全性；需要确保锁的正确获取和释放
- **测试要求**:
  - 多 category 并发创建临时文件测试
  - 锁正确性测试
  - 内存泄漏测试（sync.Map 的使用）

### 验收标准

- [ ] 不同 category 的临时文件创建可以并发执行
- [ ] 通过并发压力测试（100+ 并发，多个 category）
- [ ] 性能测试显示吞吐量提升 2-5 倍
- [ ] 无死锁或数据竞争

### 备注

- 当前实现中，`storage.go:94` 使用 `os.CreateTemp("", ...)` 直接创建临时文件，可能不在 TempFileManager 管理范围内
- 如果未来启用 TempFileManager，会立即成为瓶颈，建议提前优化

---

## 🟡 P2 - 缓存清理锁内遍历优化

### Issue #003: 实现 LRU 数据结构优化缓存淘汰

**状态**: 🟡 待优化  
**优先级**: P2 - 中优先级  
**创建时间**: 2025-11-05  
**预计工作量**: 2-3 天

### 问题描述

当前 `CacheManager.evictOldest()` 方法在写锁内遍历所有缓存条目（O(n) 复杂度），找到最旧的条目进行淘汰。当缓存条目较多时，这会阻塞较长时间。

**影响**:
- ⚠️ **发生频率**: 低 - 只在缓存满时触发
- ⚠️ **业务影响**: 影响缓存写入性能，但不是核心流程
- ⚠️ **性能影响**: 缓存条目多时阻塞时间较长
- ⚠️ **用户体验**: 缓存写入可能变慢

### 当前实现

```go
// cache.go:149-164
func (cm *CacheManager) evictOldest() {
    var oldestKey string
    var oldestTime time.Time
    
    for key, entry := range cm.memoryCache.cache {  // O(n) 遍历
        if oldestKey == "" || entry.Timestamp.Before(oldestTime) {
            oldestKey = key
            oldestTime = entry.Timestamp
        }
    }
    
    if oldestKey != "" {
        delete(cm.memoryCache.cache, oldestKey)
    }
}
```

### 优化方案

实现 LRU（最近最少使用）数据结构，O(1) 时间复杂度淘汰最旧的条目：

```go
// 使用双向链表 + map 实现 LRU
type LRUCache struct {
    cache    map[string]*CacheEntry
    head     *CacheEntry
    tail     *CacheEntry
    maxSize  int
    mu       sync.RWMutex
}

type CacheEntry struct {
    Key       string
    Data      []byte
    Timestamp time.Time
    prev      *CacheEntry
    next      *CacheEntry
}

func (lru *LRUCache) EvictOldest() {
    // O(1) 时间复杂度淘汰最旧的条目
    if lru.tail != nil {
        delete(lru.cache, lru.tail.Key)
        lru.removeEntry(lru.tail)
    }
}
```

### 预期收益

- **性能提升**: 淘汰操作从 O(n) 优化到 O(1)
- **延迟降低**: 缓存满时写入延迟从 10-50ms 降低到 <1ms
- **可扩展性**: 支持更大容量的缓存（1000+ 条目）

### 风险评估

- **风险等级**: 低
- **风险说明**: LRU 是成熟的数据结构，实现相对简单；需要确保链表操作的线程安全
- **测试要求**:
  - LRU 正确性测试（访问顺序验证）
  - 并发读写测试
  - 内存泄漏测试

### 验收标准

- [ ] LRU 数据结构正确实现
- [ ] 淘汰操作 O(1) 时间复杂度
- [ ] 通过并发压力测试
- [ ] 性能测试显示延迟降低 90%+

### 备注

- 优化优先级取决于缓存使用情况
- 如果缓存命中率高，缓存满的情况较少，可以暂缓优化

---

## 🟢 P3 - CheckAndUpdatePools 异步执行优化

### Issue #004: 异步执行存储池状态检查

**状态**: 🟢 待优化  
**优先级**: P3 - 低优先级  
**创建时间**: 2025-11-05  
**预计工作量**: 几小时

### 问题描述

当前 `PoolManager.CheckAndUpdatePools()` 方法在持有读锁的情况下，遍历所有存储池并更新其使用量。`updateCurrentSize()` 需要遍历文件系统，可能耗时较长，长时间持有锁会阻塞其他读操作。

**影响**:
- ✅ **发生频率**: 很低 - 通常是每小时或每天执行一次（定期任务）
- ✅ **业务影响**: 低 - 是后台任务，不阻塞核心流程
- ⚠️ **性能影响**: 可能阻塞其他读操作，但频率低
- ✅ **用户体验**: 无明显影响

### 当前实现

```go
// pool_manager.go:165-190
func (pm *PoolManager) CheckAndUpdatePools() error {
    pm.mu.RLock()  // 持有读锁
    defer pm.mu.RUnlock()
    
    for _, pool := range pm.pools {
        pool.updateCurrentSize()  // 文件系统遍历，可能耗时
    }
}
```

### 优化方案

异步执行存储池状态检查，不持有锁：

```go
func (pm *PoolManager) CheckAndUpdatePools() error {
    // 先复制池列表（读锁保护）
    pm.mu.RLock()
    pools := make([]*StoragePool, len(pm.pools))
    copy(pools, pm.pools)
    pm.mu.RUnlock()
    
    // 异步更新，不持有锁
    go func() {
        for _, pool := range pools {
            pool.updateCurrentSize()
        }
    }()
    
    return nil
}
```

### 预期收益

- **阻塞减少**: 不再阻塞其他读操作
- **响应性提升**: 定期任务立即返回，不阻塞主流程

### 风险评估

- **风险等级**: 低
- **风险说明**: 异步执行是常见模式，风险低；需要确保 goroutine 不会泄漏
- **测试要求**:
  - 并发读操作测试
  - goroutine 泄漏测试

### 验收标准

- [ ] CheckAndUpdatePools 异步执行
- [ ] 不再阻塞其他读操作
- [ ] 通过并发测试
- [ ] 无 goroutine 泄漏

### 备注

- 优化优先级较低，可以暂缓
- 如果业务量增长，定期任务执行频率增加，再考虑优化

---

## 性能优化路线图

### 第一阶段（立即，1-2天）
- [x] 🔴 **Issue #001**: 存储池大小更新锁竞争优化
  - 预计收益: 性能提升 30-50%
  - 工作量: 1-2 小时

### 第二阶段（近期，1-2周）
- [ ] 🟡 **Issue #002**: 临时文件管理器串行化优化
  - 预计收益: 并发能力提升 2-5 倍
  - 工作量: 1-2 天

### 第三阶段（中期，1-2个月）
- [ ] 🟡 **Issue #003**: 缓存清理锁内遍历优化
  - 预计收益: 延迟降低 90%+
  - 工作量: 2-3 天

### 第四阶段（长期，按需）
- [ ] 🟢 **Issue #004**: CheckAndUpdatePools 异步执行优化
  - 预计收益: 减少阻塞
  - 工作量: 几小时

---

## 性能监控指标

### 关键指标

1. **锁竞争指标**
   - 锁等待时间
   - 锁竞争次数
   - 锁持有时间

2. **操作性能指标**
   - Put 操作延迟（P50, P95, P99）
   - Get 操作延迟（P50, P95, P99）
   - Delete 操作延迟（P50, P95, P99）

3. **并发能力指标**
   - 并发请求数
   - 吞吐量（QPS）
   - 错误率

4. **资源使用指标**
   - CPU 使用率
   - 内存使用率
   - 磁盘 I/O

### 监控工具建议

- 使用 `go tool pprof` 进行性能分析
- 使用 `go test -race` 检测数据竞争
- 使用 `sync.Mutex` 的 `LockDuration` 监控锁等待时间
- 使用 Prometheus + Grafana 进行指标监控

---

## 优化记录

### 2025-11-05
- 创建性能优化 Issue 清单
- 识别 4 个性能优化点
- 制定优化路线图

---

## 参考资料

- [Go 并发编程最佳实践](https://golang.org/doc/effective_go#concurrency)
- [sync/atomic 包文档](https://pkg.go.dev/sync/atomic)
- [性能优化指南](https://github.com/golang/go/wiki/Performance)

