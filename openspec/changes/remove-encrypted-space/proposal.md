# Change: Remove Encrypted Space Feature

## Why

加密空间功能是一个复杂的特性，涉及密码管理、会话令牌、文件迁移等多个子系统。经过评估，决定完全移除该功能，原因包括：

1. **功能复杂度高**：加密空间涉及前后端多个模块，维护成本高
2. **使用率低**：该功能可能不是核心需求，移除可以简化系统架构
3. **代码清理**：移除未使用的功能可以减少代码库复杂度，提高可维护性
4. **架构简化**：移除后可以专注于核心相册功能，减少安全风险点

## What Changes

### 后端清理
- **删除服务层**：
  - `backend/internal/service/album_encryption/service.go` - 加密空间认证服务
  - `backend/internal/repository/album_session.go` - 相册会话仓储
  - `backend/internal/api/middleware/album_session.go` - 相册会话中间件

- **删除模型字段**：
  - `Album` 模型中的 `IsEncrypted`、`AlbumType`、`PasswordHash` 字段
  - `AlbumSession` 模型（整个模型删除）

- **删除 API 端点**：
  - `GET /api/v1/albums/encrypted-space` - 获取或创建加密空间
  - `POST /api/v1/albums/:albumId/password` - 设置密码
  - `POST /api/v1/albums/:albumId/password/change` - 更改密码
  - `POST /api/v1/albums/:albumId/verify-password` - 验证密码
  - `GET /api/v1/albums/:albumId/assets` - 获取加密空间资产（需要会话令牌）
  - `POST /api/v1/albums/:albumId/assets` - 添加资产到加密空间
  - `DELETE /api/v1/albums/:albumId/assets` - 从加密空间移除资产
  - `DELETE /api/v1/albums/:albumId/sessions` - 撤销所有会话令牌

- **删除仓储方法**：
  - `FindEncryptedAlbumByUserID` 方法

### 前端清理
- **删除服务文件**：
  - `lib/services/encrypted_space/encrypted_space_service.dart`
  - `lib/services/encrypted_space/file_migration_service.dart`
  - `lib/services/encrypted_space/retry_queue_service.dart`
  - `lib/services/encrypted_space/providers/encrypted_space_providers.dart`
  - `lib/services/encrypted_space/providers/encrypted_space_providers.g.dart`

- **删除页面和组件**：
  - `lib/presentation/pages/encrypted_space/encrypted_space_page.dart`
  - `lib/presentation/widgets/encrypted_space/` 目录下的所有文件

- **删除设置项**：
  - `encryptedSpaceBiometricEnabled` 设置
  - `encryptedSpaceLockTimeoutMinutes` 设置

- **删除枚举值**：
  - `AlbumType.encryptedSpace` 枚举值

- **删除数据库方法**：
  - `getOrCreateLocalEncryptedSpaceAlbum` 方法

- **移除 UI 集成**：
  - 从相册页面移除加密空间入口
  - 从照片页面移除"添加到加密空间"功能
  - 从设置页面移除加密空间设置区域
  - 删除路由定义

### 数据库迁移
- **删除表**：`album_sessions` 表
- **删除字段**：`albums` 表中的 `is_encrypted`、`album_type`、`password_hash` 字段

### 代码引用清理
- 删除所有对 `EncryptedSpaceService` 的引用
- 删除所有对 `AlbumTypeEncryptedSpace` 的引用
- 删除所有对加密空间相关设置的引用
- 删除所有对加密空间路由的引用

## Impact

- **BREAKING CHANGE**：完全移除加密空间功能，现有使用该功能的用户将无法访问加密空间
- **影响的代码**：
  - 后端：`backend/internal/api/v1/album/`、`backend/internal/service/album_encryption/`、`backend/internal/repository/`、`backend/internal/database/models/`
  - 前端：`prismbox_mobile/lib/services/encrypted_space/`、`prismbox_mobile/lib/presentation/pages/encrypted_space/`、`prismbox_mobile/lib/presentation/widgets/encrypted_space/`
- **数据库变更**：需要迁移脚本删除表和字段
- **API 变更**：删除 8 个 API 端点
- **测试影响**：删除所有加密空间相关的测试代码

