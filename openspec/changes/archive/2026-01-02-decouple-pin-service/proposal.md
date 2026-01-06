# Change: Decouple PIN Service from Encrypted Space

## Why

当前PIN码的实现与加密空间功能紧密耦合，PIN相关的服务（`SessionStorageService`、`KeyDerivationService`、`TokenEncryptionService`、`AlbumAccessControlService`）都硬编码了"相册"（album）的概念和加密空间的命名空间前缀。这导致：

1. **无法复用**：PIN码功能无法在其他场景中使用（如文件夹加密、文档保护等）
2. **测试困难**：PIN相关逻辑与业务逻辑混合，难以独立测试
3. **维护成本高**：修改PIN逻辑会影响加密空间代码，职责不清晰
4. **扩展性差**：添加新的PIN保护场景需要重复实现

通过将PIN码功能抽象为独立的基础设施服务，可以在保持向后兼容的前提下，实现更好的模块化和可复用性。

## What Changes

- **新增独立的PIN服务层**（`lib/services/pin/`）：
  - `PinAuthService`：处理PIN码的认证逻辑（设置、验证、更改）
  - `PinSessionService`：管理会话令牌的存储和检索
  - `PinKeyDerivationService`：从PIN码派生加密密钥（PBKDF2）
  - `PinTokenEncryptionService`：会话令牌的加密/解密（AES）
  - `PinAccessControlService`：管理资源的解锁状态和自动锁定

- **引入配置抽象**（`PinServiceConfig`）：
  - 可配置的存储键名前缀（替代硬编码的`encrypted_space_`）
  - 可配置的资源类型名称（用于日志和错误消息）
  - 可配置的默认会话超时时间

- **重构加密空间服务**：
  - `EncryptedSpaceService`使用通用的PIN服务
  - 通过配置适配层保持API兼容性
  - 移除加密空间目录下的PIN相关服务代码

- **保持向后兼容**：
  - 对外API接口保持不变
  - 数据迁移透明（存储键名保持不变）

## Impact

- **新增能力**：`pin` capability（PIN码服务规范）
- **影响的代码**：
  - `mobile/lib/services/encrypted_space/` 目录下的PIN相关服务
  - `mobile/lib/services/encrypted_space/encrypted_space_service.dart`（使用新的PIN服务）
  - 所有调用PIN相关服务的UI组件和业务逻辑
- **新增代码**：
  - `mobile/lib/services/pin/` 目录（新的PIN服务层）
- **测试影响**：需要为新的PIN服务编写独立测试，并更新加密空间相关的测试

