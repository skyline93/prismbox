# Design: PIN Service Decoupling

## Context

当前PIN码实现位于 `lib/services/encrypted_space/` 目录下，与加密空间功能紧密耦合。服务中硬编码了：
- `albumId` 参数（应该泛型化为 `resourceId`）
- `encrypted_space_` 存储键名前缀
- `album` 相关的命名和概念

本次重构的目标是将PIN码功能抽象为独立的基础设施服务，使其可以在任何需要PIN保护的场景中复用。

## Goals / Non-Goals

### Goals
- 将PIN相关服务从加密空间模块中完全解耦
- 通过配置抽象支持不同的资源类型和命名空间
- 保持向后兼容，不破坏现有API
- 提供清晰的接口，便于测试和复用

### Non-Goals
- 不改变PIN码的加密算法和安全性实现
- 不改变后端API接口
- 不改变用户可见的功能和行为
- 不进行数据库schema变更

## Decisions

### Decision 1: 使用配置对象抽象命名空间

**What**: 引入 `PinServiceConfig` 类来配置存储键名前缀、资源类型名称和超时时间。

**Why**: 
- 允许不同的资源类型使用不同的命名空间（如 `encrypted_space_`、`secure_folder_`）
- 便于测试（可以创建测试专用的配置）
- 支持未来扩展（如不同的加密参数）

**Alternatives considered**:
- **选项A**：使用全局常量。❌ 无法支持多种资源类型
- **选项B**：通过构造函数参数传递。❌ 参数过多，使用不便
- **选项C**：使用配置对象。✅ 灵活且易用

### Decision 2: 资源ID泛型化

**What**: 将所有服务中的 `albumId: String` 参数改为 `resourceId: String`。

**Why**:
- 移除对"相册"概念的硬依赖
- 使服务可以用于任何资源类型
- 保持类型安全（仍为String类型）

**Alternatives considered**:
- **选项A**：使用泛型类型参数 `ResourceId<T>`。❌ 过度设计，String已足够
- **选项B**：创建资源ID类。❌ 增加复杂度，没有实际收益
- **选项C**：使用String。✅ 简单且足够

### Decision 3: 服务工厂模式

**What**: 提供 `PinServiceFactory` 用于创建配置好的PIN服务实例。

**Why**:
- 简化服务创建流程
- 确保配置正确性
- 便于依赖注入

**Alternatives considered**:
- **选项A**：直接构造函数。❌ 配置分散，容易出错
- **选项B**：静态工厂方法。✅ 集中管理，易于使用

### Decision 4: 分阶段迁移策略

**What**: 
1. 先创建新的PIN服务
2. 加密空间服务适配新服务（保持API兼容）
3. 逐步迁移调用方
4. 最后删除旧代码

**Why**:
- 降低风险，可以逐步验证
- 保持系统可运行
- 便于回滚

**Alternatives considered**:
- **选项A**：一次性替换。❌ 风险高，难以测试
- **选项B**：分阶段迁移。✅ 安全可控

### Decision 5: 保持存储键名兼容

**What**: 加密空间使用新PIN服务时，配置相同的存储键名前缀（`encrypted_space_`）。

**Why**:
- 无需数据迁移
- 现有会话令牌仍然有效
- 用户体验无感知

**Alternatives considered**:
- **选项A**：更改存储键名。❌ 需要数据迁移，用户体验受影响
- **选项B**：保持键名。✅ 无缝迁移

## Architecture

### 新的服务层结构

```
lib/services/pin/
├── pin_auth_service.dart          # PIN认证服务
├── pin_session_service.dart        # 会话存储服务
├── pin_key_derivation_service.dart # 密钥派生服务
├── pin_token_encryption_service.dart # 令牌加密服务
├── pin_access_control_service.dart # 访问控制服务
├── pin_service_config.dart         # 配置类
└── pin_service_factory.dart        # 服务工厂
```

### 服务职责划分

1. **PinAuthService**: 
   - 与后端API交互（设置、验证、更改PIN）
   - 不涉及存储和加密细节

2. **PinSessionService**:
   - 会话令牌的安全存储（使用FlutterSecureStorage）
   - 令牌的加密/解密协调
   - 过期时间管理

3. **PinKeyDerivationService**:
   - 从PIN码派生加密密钥（PBKDF2）
   - 密钥缓存管理

4. **PinTokenEncryptionService**:
   - 会话令牌的加密/解密（AES）

5. **PinAccessControlService**:
   - 资源的解锁/锁定状态管理
   - 自动锁定计时器
   - 应用生命周期处理

### 配置抽象

```dart
class PinServiceConfig {
  final String storageKeyPrefix;  // 如: 'encrypted_space_'
  final String resourceTypeName;  // 如: 'album'
  final Duration defaultSessionTimeout;
}
```

## Risks / Trade-offs

### Risk 1: 迁移过程中的兼容性问题

**Mitigation**: 
- 保持存储键名前缀不变
- 分阶段迁移，充分测试
- 保留旧代码直到确认无问题

### Risk 2: 配置错误导致数据丢失

**Mitigation**:
- 配置通过工厂方法创建，减少手动配置错误
- 添加配置验证
- 充分的单元测试覆盖

### Risk 3: 性能影响

**Trade-off**: 
- 新增配置对象可能带来轻微性能开销
- 收益：更好的模块化和可维护性
- 评估：配置对象创建开销可忽略不计

### Risk 4: 代码重复

**Mitigation**:
- 仔细设计抽象，避免不必要的重复
- 代码审查时关注重复代码

## Migration Plan

### Phase 1: 创建新的PIN服务
1. 创建 `lib/services/pin/` 目录
2. 实现所有PIN服务（基于现有代码重构）
3. 编写单元测试

### Phase 2: 适配加密空间
1. 更新 `EncryptedSpaceService` 使用新的PIN服务
2. 配置适配层（使用 `encrypted_space_` 前缀）
3. 运行集成测试验证功能

### Phase 3: 迁移调用方
1. 更新所有UI组件使用新的服务接口
2. 验证所有功能正常

### Phase 4: 清理
1. 删除 `encrypted_space/` 目录下的PIN相关服务
2. 更新文档

## Open Questions

1. 是否需要在配置中支持自定义加密算法参数？（当前使用固定参数）
   - **Decision**: 暂时不支持，保持简单。未来需要时可以扩展。

2. 是否需要支持多个PIN服务实例（不同配置）？
   - **Decision**: 支持。通过不同的配置对象创建不同的服务实例。

