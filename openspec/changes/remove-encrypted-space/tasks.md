# Tasks: Remove Encrypted Space Feature

## 1. 前端代码清理

- [x] 1.1 删除加密空间服务目录
  - 删除 `prismbox_mobile/lib/services/encrypted_space/encrypted_space_service.dart`
  - 删除 `prismbox_mobile/lib/services/encrypted_space/file_migration_service.dart`
  - 删除 `prismbox_mobile/lib/services/encrypted_space/retry_queue_service.dart`
  - 删除 `prismbox_mobile/lib/services/encrypted_space/providers/encrypted_space_providers.dart`
  - 删除 `prismbox_mobile/lib/services/encrypted_space/providers/encrypted_space_providers.g.dart`

- [x] 1.2 删除加密空间页面和组件
  - 删除 `prismbox_mobile/lib/presentation/pages/encrypted_space/encrypted_space_page.dart`
  - 删除 `prismbox_mobile/lib/presentation/widgets/encrypted_space/password_setup_dialog.dart`
  - 删除 `prismbox_mobile/lib/presentation/widgets/encrypted_space/password_verify_dialog.dart`
  - 删除 `prismbox_mobile/lib/presentation/widgets/encrypted_space/password_verification_dialog.dart`
  - 删除 `prismbox_mobile/lib/presentation/widgets/encrypted_space/pin_input_widget.dart`

- [x] 1.3 从相册页面移除加密空间功能
  - 删除 `prismbox_mobile/lib/presentation/pages/albums/albums_page.dart` 中的 `_handleEncryptedSpaceTap` 方法
  - 删除加密空间相关的导入（第6-8行）
  - 删除加密空间列表项（第460-461行）

- [x] 1.4 从照片页面移除加密空间功能
  - 删除 `prismbox_mobile/lib/presentation/pages/photos/main_timeline_page.dart` 中的 `_handleAddToEncryptedSpace` 方法（第606-808行）
  - 删除加密空间相关的导入（第28-30行）
  - 删除 `onAddToEncryptedSpace` 回调（第397-398行）

- [x] 1.5 从设置页面移除加密空间功能
  - 删除 `prismbox_mobile/lib/presentation/pages/settings/preferences_page.dart` 中的 `_initializeEncryptedSpace` 方法（第40-58行）
  - 删除 `_buildEncryptedSpaceSection` 方法（第362-480行）
  - 删除加密空间相关的导入（第8、11行）
  - 删除加密空间相关的状态变量（第29-30行）
  - 删除加密空间设置区域的调用（第350-351行）

- [x] 1.6 删除路由定义
  - 从 `prismbox_mobile/lib/presentation/routing/app_router.gr.dart` 删除 `EncryptedSpaceRoute` 相关代码（第36-39行，第171-179行）
  - 如果存在 `app_router.dart`，删除 `EncryptedSpaceRoute` 的定义

- [x] 1.7 删除设置项定义
  - 从 `prismbox_mobile/lib/core/settings/app_setting.dart` 删除 `encryptedSpaceBiometricEnabled` 设置（第33行）
  - 从 `prismbox_mobile/lib/core/settings/app_setting.dart` 删除 `encryptedSpaceLockTimeoutMinutes` 设置（第38行）
  - 从 `prismbox_mobile/lib/core/storage/store_key.dart` 删除对应的键定义

- [x] 1.8 删除枚举值
  - 从 `prismbox_mobile/lib/data/database/enums/album_type.dart` 删除 `encryptedSpace` 枚举值（第9行）

- [x] 1.9 删除数据库方法
  - 从 `prismbox_mobile/lib/data/database/daos/album_dao.dart` 删除 `getOrCreateLocalEncryptedSpaceAlbum` 方法（第164-190行）

- [x] 1.10 删除测试代码中的引用
  - 从 `prismbox_mobile/test/services/pin/pin_service_integration_test.dart` 删除 `createEncryptedSpaceSuite` 的引用（第26行）

- [x] 1.11 删除 PIN 服务工厂中的加密空间配置
  - 从 `prismbox_mobile/lib/services/pin/pin_service_factory.dart` 删除 `createEncryptedSpaceSuite` 方法
  - 从 `prismbox_mobile/lib/services/pin/pin_service_factory.dart` 删除 `createEncryptedSpaceConfig` 方法

- [ ] 1.12 编译验证前端代码
  - 运行 `flutter pub get`
  - 运行 `flutter analyze`
  - 运行 `flutter build` 验证编译成功

## 2. 后端代码清理

- [x] 2.1 删除加密空间服务
  - 删除 `backend/internal/service/album_encryption/service.go`

- [x] 2.2 删除相册会话仓储
  - 删除 `backend/internal/repository/album_session.go`

- [x] 2.3 删除相册会话中间件
  - 删除 `backend/internal/api/middleware/album_session.go`

- [x] 2.4 修改相册模型
  - 从 `backend/internal/database/models/album.go` 删除 `AlbumTypeEncryptedSpace` 常量（第14行）
  - 从 `backend/internal/database/models/album.go` 删除 `AlbumSession` 模型（第51-76行）
  - 从 `Album` 模型删除 `IsEncrypted` 字段（第38行）
  - 从 `Album` 模型删除 `AlbumType` 字段（第39行）
  - 从 `Album` 模型删除 `PasswordHash` 字段（第40行）

- [x] 2.5 删除 API Handler 方法
  - 从 `backend/internal/api/v1/album/handler.go` 删除 `GetOrCreateEncryptedSpace` 方法（第437-466行）
  - 从 `backend/internal/api/v1/album/handler.go` 删除 `GetAssets` 方法（第468-527行）
  - 从 `backend/internal/api/v1/album/handler.go` 删除 `AddAssets` 方法（第273-327行）
  - 从 `backend/internal/api/v1/album/handler.go` 删除 `RemoveAssets` 方法（第329-375行）
  - 从 `backend/internal/api/v1/album/handler.go` 删除 `SetPassword` 方法（第150-199行）
  - 从 `backend/internal/api/v1/album/handler.go` 删除 `ChangePassword` 方法（第201-242行）
  - 从 `backend/internal/api/v1/album/handler.go` 删除 `VerifyPassword` 方法（第244-271行）
  - 从 `backend/internal/api/v1/album/handler.go` 删除 `RevokeAllSessions` 方法（第255-271行）
  - 删除相关的输入/输出结构体（`SetPasswordInput`, `ChangePasswordInput`, `VerifyPasswordInput`, `AddAssetsInput`, `RemoveAssetsInput` 等）

- [x] 2.6 删除 API 路由
  - 从 `backend/internal/api/v1/album/routes.go` 删除所有加密空间相关路由（第29-45行）

- [x] 2.7 删除仓储方法
  - 从 `backend/internal/repository/album.go` 删除 `FindEncryptedAlbumByUserID` 方法（第60-69行）

- [x] 2.8 删除仓储接口
  - 从 `backend/internal/repository/interfaces.go` 删除 `AlbumSessionRepository` 接口定义（第244-252行）

- [x] 2.9 修改 App Builder
  - 从 `backend/internal/app/builder.go` 删除 `AlbumEncryptionService` 的初始化（第350-356行）
  - 从 `backend/internal/app/builder.go` 删除 `AlbumSessionRepository` 的初始化（第350行）

- [x] 2.10 修改 App 结构
  - 从 `backend/internal/app/app.go` 删除 `AlbumEncryptionService` 字段

- [x] 2.11 修改数据库迁移
  - 从 `backend/internal/database/migrate.go` 删除 `AlbumSession` 模型的迁移（第19行）

- [x] 2.12 修改路由注册
  - 从 `backend/internal/api/router.go` 删除路由注册中的注释（第94行）

- [ ] 2.13 编译验证后端代码
  - 运行 `go mod tidy`
  - 运行 `go build ./...`
  - 运行 `go test ./...` 验证测试通过

## 3. 数据库迁移

- [x] 3.1 创建迁移脚本删除 album_sessions 表
  - 创建迁移文件删除 `album_sessions` 表
  - 在迁移文件中添加适当的注释说明

- [x] 3.2 创建迁移脚本删除 albums 表中的加密相关字段
  - 创建迁移文件删除 `albums` 表中的 `is_encrypted` 字段
  - 创建迁移文件删除 `albums` 表中的 `album_type` 字段
  - 创建迁移文件删除 `albums` 表中的 `password_hash` 字段
  - 在迁移文件中添加适当的注释说明

- [ ] 3.3 测试数据库迁移
  - 在测试环境执行迁移脚本
  - 验证表结构正确
  - 验证数据完整性

## 4. 代码引用清理

- [x] 4.1 搜索并删除所有对 EncryptedSpaceService 的引用
  - 使用 `grep -r "EncryptedSpaceService"` 搜索所有引用
  - 删除或修改相关代码

- [x] 4.2 搜索并删除所有对 AlbumTypeEncryptedSpace 的引用
  - 使用 `grep -r "AlbumTypeEncryptedSpace"` 搜索所有引用
  - 删除或修改相关代码

- [x] 4.3 搜索并删除所有对加密空间设置的引用
  - 使用 `grep -r "encryptedSpace"` 搜索所有引用
  - 删除或修改相关代码

- [x] 4.4 搜索并删除所有对加密空间路由的引用
  - 使用 `grep -r "EncryptedSpaceRoute"` 搜索所有引用
  - 删除或修改相关代码

- [x] 4.5 检查文档和注释
  - 搜索文档目录中的加密空间相关引用
  - 删除或更新相关文档
  - 删除代码注释中的加密空间相关说明

## 5. 最终验证

- [ ] 5.1 编译验证
  - 前端：`flutter build` 成功
  - 后端：`go build ./...` 成功

- [ ] 5.2 运行测试
  - 前端：运行所有测试
  - 后端：运行所有测试

- [ ] 5.3 验证 API 端点已删除
  - 尝试访问已删除的 API 端点，确认返回 404

- [ ] 5.4 验证 UI 中无加密空间入口
  - 检查相册页面无加密空间入口
  - 检查照片页面无"添加到加密空间"选项
  - 检查设置页面无加密空间设置

- [ ] 5.5 代码质量检查
  - 运行 linter 检查
  - 修复所有警告和错误
