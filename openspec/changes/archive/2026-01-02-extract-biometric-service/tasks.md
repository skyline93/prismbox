## 1. 准备阶段
- [x] 1.1 确认所有使用 `BiometricAuthService` 的文件位置
- [x] 1.2 分析每个使用场景，了解错误处理需求
- [x] 1.3 检查是否有测试文件需要更新

## 2. 设计新接口
- [x] 2.1 定义 `BiometricAuthResult` 类（包含 success、failure、biometricType）
- [x] 2.2 定义 `BiometricAuthFailure` 枚举（所有可能的失败类型）
- [x] 2.3 定义 `BiometricAuthOptions` 配置类（认证选项）
- [x] 2.4 设计新的服务接口方法签名

## 3. 实现新服务
- [x] 3.1 创建新目录 `lib/services/biometric/`
- [x] 3.2 实现新的 `BiometricAuthService` 类
- [x] 3.3 实现所有方法，返回 `BiometricAuthResult`
- [x] 3.4 改进错误处理，提供详细的错误信息
- [x] 3.5 更新文件头部注释（移除加密空间相关说明，改为通用说明）

## 4. 更新所有调用代码
- [x] 4.1 更新 `lib/services/encrypted_space/album_access_control_service.dart`
- [x] 4.2 更新 `lib/presentation/pages/albums/albums_page.dart`
- [x] 4.3 更新 `lib/presentation/pages/photos/main_timeline_page.dart`
- [x] 4.4 更新 `lib/presentation/pages/settings/preferences_page.dart`
- [x] 4.5 更新 `lib/presentation/widgets/encrypted_space/password_verify_dialog.dart`
- [x] 4.6 使用 `grep` 搜索所有其他可能的引用并更新
- [x] 4.7 适配新的返回类型，更新错误处理逻辑

## 5. 代码质量检查
- [x] 5.1 运行 `flutter analyze` 检查是否有编译错误

## 6. 测试和文档
- [x] 6.1 添加单元测试（特别是错误场景）
- [x] 6.2 更新代码注释和文档
- [x] 6.3 如有相关文档，更新文档中的接口说明

