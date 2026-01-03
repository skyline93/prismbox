## 1. Implementation

- [x] 1.1 在 `TrashStorageService` 中新增 `deleteMultipleFromSystemAlbum()` 方法
  - [x] 1.1.1 添加方法签名，接收 `List<String> assetIds` 参数
  - [x] 1.1.2 实现资产 ID 有效性验证逻辑
  - [x] 1.1.3 调用 `PhotoManager.editor.deleteWithIds()` 批量删除
  - [x] 1.1.4 处理返回结果，记录成功和失败的资产 ID
  - [x] 1.1.5 添加错误处理和日志记录

- [x] 1.2 优化 `LocalAssetDeleteService.softDeleteAssets()` 方法
  - [x] 1.2.1 重构批量删除流程，分为两个阶段：
    - 阶段一：批量处理文件复制和数据库更新（不涉及系统相册删除）
    - 阶段二：统一批量删除系统相册资产
  - [x] 1.2.2 收集成功处理的所有资产 ID
  - [x] 1.2.3 在阶段二统一调用 `deleteMultipleFromSystemAlbum()`
  - [x] 1.2.4 记录删除结果和失败信息

- [x] 1.3 代码质量检查
  - [x] 1.3.1 运行 linter 检查代码格式
  - [x] 1.3.2 确认日志记录完整
  - [x] 1.3.3 确认错误处理完善

