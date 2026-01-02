## Context

当前 `BiometricAuthService` 位于加密空间模块目录下，但实际上它是一个完全通用的平台服务封装。该服务：
- 仅依赖 `local_auth` 包（Flutter 官方生物识别插件）
- 不包含任何业务逻辑
- 提供纯技术层面的设备生物识别功能封装
- 可以被任何需要生物识别认证的功能模块使用

**长远使用场景考虑**：
- 加密空间解锁（当前）
- 应用启动锁（未来）
- 敏感操作验证（支付、删除等）
- 设置项保护（修改关键配置）
- 多因素认证（结合密码/PIN）

## Goals / Non-Goals

### Goals
- 将生物识别服务提取为通用服务，放在合适的目录结构下
- **重构接口设计**：基于长远架构考虑，设计更通用、更灵活的接口
- **改进错误处理**：提供详细的错误信息和类型，便于调用方处理不同场景
- 为后续功能（如应用锁、敏感操作验证）提供可复用的生物识别能力
- 支持多种使用场景和配置选项

### Non-Goals
- **不保持向后兼容**：采用新的接口设计，所有调用代码需要更新
- 不添加业务逻辑（保持为纯技术封装）
- 不实现具体的业务场景（如应用锁），仅提供基础能力

## Decisions

### Decision: 目录结构选择
**决策**：将服务放在 `lib/services/biometric/` 目录下

**理由**：
- 符合项目分层架构规范（服务层）
- 使用功能名称作为目录名（`biometric`），清晰明确
- 与其他服务目录结构一致（如 `lib/services/auth/`）

**替代方案考虑**：
- `lib/services/auth/biometric_auth_service.dart` - 但生物识别不仅用于认证，也可能用于其他场景
- `lib/core/biometric/` - 但这是服务层功能，不是核心层功能

### Decision: 保持单例模式
**决策**：保持单例模式实现

**理由**：
- 生物识别服务是无状态的，单例模式合适
- 避免重复创建实例，提高性能
- 简化使用方式，无需依赖注入

### Decision: 重构接口设计
**决策**：采用结果对象模式，返回 `BiometricAuthResult` 而不是简单的 `bool`

**理由**：
- **更好的错误处理**：调用方可以区分不同类型的错误（设备不支持、用户取消、认证失败等）
- **更灵活的使用场景**：不同场景可能需要不同的错误处理策略
- **更好的可扩展性**：未来可以添加更多信息（如认证类型、时间戳等）
- **符合现代API设计**：结果对象模式更清晰、更易维护

**接口设计**：
```dart
class BiometricAuthResult {
  final bool success;
  final BiometricAuthFailure? failure;
  final BiometricType? biometricType; // 使用的生物识别类型
}

enum BiometricAuthFailure {
  deviceNotSupported,    // 设备不支持
  noBiometricsAvailable, // 无可用的生物识别方法
  userCancel,            // 用户取消
  authenticationFailed,  // 认证失败
  systemError,           // 系统错误
}
```

### Decision: 支持灵活的配置选项
**决策**：提供配置类 `BiometricAuthOptions` 来支持不同场景的需求

**理由**：
- 不同场景可能需要不同的认证行为（如是否允许使用设备密码作为fallback）
- 支持未来扩展更多配置选项
- 保持方法签名简洁，配置通过选项对象传递

**配置选项**：
```dart
class BiometricAuthOptions {
  final bool biometricOnly;      // 仅使用生物识别（默认true）
  final bool useErrorDialogs;    // 使用系统错误对话框（默认true）
  final bool stickyAuth;         // 粘性认证（默认true）
  final String? cancelButtonText; // 取消按钮文本（可选）
}
```

## Risks / Trade-offs

### 风险
- **接口变更影响**：所有调用代码需要更新，可能遗漏某些文件
  - **缓解措施**：使用 `grep` 全面搜索所有引用，编译时检查，运行时测试

- **迁移复杂度**：接口变更比路径变更更复杂，需要理解新接口并适配
  - **缓解措施**：提供清晰的迁移指南，新接口设计更直观易用

- **测试覆盖**：重构可能影响现有功能
  - **缓解措施**：充分测试所有使用场景，确保功能正常

### 权衡
- **接口改进 vs 迁移成本**：选择改进接口设计，接受一次性迁移成本，长期收益更大
- **通用性 vs 简单性**：选择通用性，设计更灵活的接口，支持未来更多场景
- **向后兼容 vs 架构优化**：选择架构优化，不保持向后兼容，采用更好的设计

## Migration Plan

### 步骤
1. **创建新目录和文件结构**：`lib/services/biometric/`
2. **重构服务实现**：
   - 定义 `BiometricAuthResult` 和 `BiometricAuthFailure` 类型
   - 定义 `BiometricAuthOptions` 配置类
   - 重构 `BiometricAuthService` 实现新接口
3. **更新所有调用代码**：
   - 更新导入路径
   - 适配新的返回类型（从 `bool` 改为 `BiometricAuthResult`）
   - 更新错误处理逻辑
4. **验证功能**：运行应用测试所有生物识别使用场景
5. **清理**：确认无遗漏后，删除原文件

### 迁移示例

**旧代码**：
```dart
final result = await biometricAuthService.authenticate(
  reason: '请使用生物识别验证',
);
if (result) {
  // 成功
} else {
  // 失败（不知道具体原因）
}
```

**新代码**：
```dart
final result = await biometricAuthService.authenticate(
  reason: '请使用生物识别验证',
);
if (result.success) {
  // 成功
} else {
  // 根据 failure 类型处理不同场景
  switch (result.failure) {
    case BiometricAuthFailure.userCancel:
      // 用户取消，可能不需要提示错误
      break;
    case BiometricAuthFailure.deviceNotSupported:
      // 设备不支持，提示用户
      break;
    // ...
  }
}
```

### 回滚
如果出现问题，可以：
1. 恢复原文件
2. 恢复所有调用代码
3. 功能完全恢复，无数据丢失风险

## Open Questions

- 是否需要为生物识别服务添加单元测试？（当前无测试文件）
  - **建议**：添加单元测试，特别是错误场景的测试

- 是否需要支持认证结果回调？（当前是同步返回结果）
  - **当前决策**：保持同步返回，简单直接，满足当前需求
  - **未来考虑**：如果需要在认证过程中执行额外操作，可以考虑添加回调

- 是否需要支持批量认证或认证队列？
  - **当前决策**：不支持，单次认证足够
  - **未来考虑**：如果出现并发认证需求，再考虑添加

