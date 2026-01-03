## 1. 修改 LocalAsset 实体定义

- [x] 1.1 在 `LocalAsset` 实体类中添加 `isUploaded` 字段（bool 类型）
- [x] 1.2 修改 `LocalAsset.fromData` 工厂方法，添加 `isUploaded` 参数
- [x] 1.3 更新所有创建 `LocalAsset` 的地方，从数据库实体中读取 `isUploaded` 字段并传递

## 2. 实现过滤逻辑重构

- [x] 2.1 实现"全部"模式过滤逻辑：仅展示本地媒体资源（LocalAsset），包括已上传和未上传的
- [x] 2.2 实现"已备份"模式过滤逻辑：仅展示已上传的本地媒体资源（`isUploaded == true`）
- [x] 2.3 实现"未备份"模式过滤逻辑：仅展示未上传的本地媒体资源（`isUploaded == false`，包括从未上传和上传失败的）
- [x] 2.4 实现"仅云端"模式过滤逻辑：仅展示远程媒体资源（RemoteAsset）

## 3. 代码质量

- [x] 3.1 更新相关代码注释，反映新的过滤逻辑（仅使用 `isUploaded` 字段，不查询上传任务表）
- [x] 3.2 确保代码符合项目规范（类型安全、错误处理等）
- [x] 3.3 运行 linter 检查，修复所有警告

