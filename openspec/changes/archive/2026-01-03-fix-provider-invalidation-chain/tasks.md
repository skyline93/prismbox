## 1. 修复删除照片后页面不更新问题

- [x] 1.1 修改 `TimelineDeleteHandler.handleDelete()` 方法
  - [x] 在删除操作完成后，同时 invalidate `timelineAssetsProvider()` 和 `timelineSectionsProvider`
  - [x] 确保先 invalidate 依赖的 provider（`timelineAssetsProvider()`），再 invalidate 当前 provider（`timelineSectionsProvider`）

## 2. 修复恢复照片后回收站页面不更新问题

- [x] 2.1 修改 `TrashPage._handleRestore()` 方法
  - [x] 在恢复操作完成后，同时 invalidate `trashAssetsProvider` 和 `trashSectionsProvider`
  - [x] 确保先 invalidate 依赖的 provider（`trashAssetsProvider`），再 invalidate 当前 provider（`trashSectionsProvider`）

## 3. 修复永久删除后回收站页面不更新问题

- [x] 3.1 修改 `TrashPage._handlePurge()` 方法
  - [x] 在永久删除操作完成后，同时 invalidate `trashAssetsProvider` 和 `trashSectionsProvider`
  - [x] 确保先 invalidate 依赖的 provider（`trashAssetsProvider`），再 invalidate 当前 provider（`trashSectionsProvider`）

## 4. 代码验证

- [x] 4.1 运行 linter 检查代码格式
- [x] 4.2 验证修改后的代码符合项目规范

