# Tasks: 后端统一计算文件 Hash

## 1. 修改后端 Handler 层

- [x] 1.1 修改 `backend/internal/api/v1/media/handler.go` 的 `UploadMedia` 方法
- [x] 1.2 移除 `hash` 字段的必填验证（不再需要 hash 字段）
- [x] 1.3 移除秒传检查逻辑（`CheckInstantUpload`）
- [x] 1.4 打开文件流并传递给 Service 层
- [x] 1.5 更新 Swagger 文档注释，移除 `hash` 参数

## 2. 修改后端 Service 层

- [x] 2.1 修改 `backend/internal/service/media/service.go` 的 `UploadMedia` 方法
- [x] 2.2 移除 `hash` 参数（从 `UploadMediaRequest` 结构体中移除）
- [x] 2.3 从文件流计算 hash（使用 `hashutil.CalculateHashMD5`）
- [x] 2.4 使用计算得到的 hash 构建存储 key
- [x] 2.5 确保文件流可以重复读取（使用临时文件）
- [x] 2.6 使用计算得到的 hash 创建 media 模型

## 3. 处理文件流重复读取问题

- [x] 3.1 分析文件流读取需求（计算 hash、检测 MIME 类型、存储）
- [x] 3.2 实现文件流复用方案（使用临时文件）
- [x] 3.3 确保在计算 hash 后，文件流可以用于存储

## 4. 更新前端代码

- [x] 4.1 修改 `mobile/lib/services/backup/upload_orchestrator.dart`
- [x] 4.2 移除 `FileHashUtil.calculateFileChecksum` 调用
- [x] 4.3 移除 `hash` 字段
- [x] 4.4 移除 `FileHashUtil` 和相关导入
- [x] 4.5 移除 TODO 注释

## 5. 更新文档

- [x] 5.1 更新 API 文档（Swagger），移除 `hash` 参数
- [x] 5.2 更新代码注释，说明后端统一计算 hash 的逻辑

