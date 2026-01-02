# Change: 提取并重构生物识别服务为通用服务

## Why

当前 `BiometricAuthService` 位于 `lib/services/encrypted_space/` 目录下，但实际上它是一个完全通用的服务，不依赖任何加密空间特定的业务逻辑。该服务仅依赖平台级别的 `local_auth` 包，提供设备生物识别功能的封装。

将生物识别服务提取并重构为通用组件可以：
- **提高代码复用性**：其他功能模块（如应用锁、敏感操作验证、支付确认等）可以复用生物识别功能
- **符合架构规范**：通用服务应该放在通用目录，而不是特定功能模块目录
- **便于维护和扩展**：集中管理生物识别相关功能，支持未来更多使用场景
- **改进接口设计**：基于长远架构考虑，设计更通用、更灵活的接口，支持更丰富的使用场景
- **为后续功能做准备**：为清理加密空间功能做准备，确保通用组件不被误删

## What Changes

- **提取并重构生物识别服务**：将 `BiometricAuthService` 从 `lib/services/encrypted_space/` 移动到 `lib/services/biometric/`，并重构接口设计
- **改进接口设计**：
  - 使用结果对象（`BiometricAuthResult`）替代简单的 `bool` 返回值，提供更详细的错误信息
  - 支持更灵活的配置选项（认证模式、错误处理策略等）
  - 改进错误处理，提供明确的错误类型和原因
- **更新所有引用**：更新所有使用 `BiometricAuthService` 的文件，适配新的接口
- **新增规范文档**：在 spec 中定义生物识别认证的标准接口和行为

**BREAKING**: 
- 导入路径变更
- 接口变更：返回值从 `bool` 改为 `BiometricAuthResult`
- 方法签名可能调整，所有调用代码需要更新

## Impact

- **受影响文件**：
  - `prismbox_mobile/lib/services/encrypted_space/biometric_auth_service.dart` → 重构后移动到 `lib/services/biometric/biometric_auth_service.dart`
  - 所有引用该服务的文件（约 10+ 个文件）需要更新导入路径和调用方式
- **受影响模块**：
  - 加密空间模块（当前唯一使用者，需要适配新接口）
  - 未来可能使用生物识别的其他模块（将受益于改进的接口设计）
- **新增规范**：
  - `openspec/specs/biometric-auth/spec.md` - 生物识别认证能力规范
- **向后兼容性**：**不保持向后兼容**，采用新的接口设计，所有调用代码需要更新

