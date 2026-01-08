# asset-upload Specification

## Purpose
TBD - created by archiving change decouple-local-remote-assets. Update Purpose after archive.
## Requirements
### Requirement: 资产上传

系统 SHALL 提供资产上传功能，将本地资产上传到服务器。上传功能 SHALL 基于 `isUploaded` 字段进行去重，不依赖 checksum 关联。上传完成后，系统 SHALL 通过 `orchestrateUpload` 的返回值提供媒体 UUID，确保调用方可以立即获取 UUID 而不需要轮询数据库。

#### Scenario: 上传前过滤
- **WHEN** 准备上传资产列表
- **THEN** 系统 SHALL 查询本地资产表的 `isUploaded` 字段
- **AND** 系统 SHALL 过滤掉 `isUploaded = true` 的资产
- **AND** 系统 SHALL 只对未上传的资产创建上传任务
- **AND** 系统 SHALL 不计算文件 hash（由后端计算）

#### Scenario: 上传执行
- **WHEN** 执行上传任务
- **THEN** 系统 SHALL 将文件上传到服务器
- **AND** 系统 SHALL 不在前端计算文件 hash
- **AND** 后端 SHALL 接收文件后计算 hash
- **AND** 后端 SHALL 检查 hash 是否已存在（秒传判断）

#### Scenario: 上传成功处理
- **WHEN** 上传任务状态变为 `completed`
- **THEN** 系统 SHALL 更新本地资产的 `isUploaded = true`
- **AND** 系统 SHALL 确保更新操作的原子性
- **AND** 系统 SHALL 处理更新失败的情况（记录日志但不阻塞流程）
- **AND** 秒传成功也 SHALL 视为上传成功
- **AND** 系统 SHALL 从上传响应中提取媒体 UUID 并存储到数据库
- **AND** 系统 SHALL 在 `orchestrateUpload` 返回前，确保 UUID 已存储完成（等待最多 1 秒）

#### Scenario: 上传结果返回
- **WHEN** `orchestrateUpload` 方法完成
- **THEN** 系统 SHALL 返回 `UploadResult` 对象
- **AND** `UploadResult` SHALL 包含 `mediaUuids` 字段（`Map<String, String>?`，可选）
- **AND** `mediaUuids` 的键 SHALL 为任务 ID（`taskId`），值 SHALL 为媒体 UUID（`mediaUuid`）
- **AND** 系统 SHALL 确保返回时所有成功任务的 UUID 已存储完成
- **AND** 如果 UUID 存储超时（1 秒后仍无 UUID），系统 SHALL 抛出异常
- **AND** 对于不需要 UUID 的场景（如备份上传），`mediaUuids` 可以为空

#### Scenario: 上传失败处理
- **WHEN** 上传任务失败、取消或暂停
- **THEN** 系统 SHALL 保持 `isUploaded = false`
- **AND** 系统 SHALL 允许重试上传
- **AND** 系统 SHALL 不更新 `isUploaded` 字段

#### Scenario: 多设备上传
- **WHEN** 设备A已上传资产，设备B也有相同资产
- **THEN** 设备B SHALL 可以创建上传任务（`isUploaded = false`）
- **AND** 后端 SHALL 通过 hash 检测到重复文件
- **AND** 后端 SHALL 返回秒传成功（不存储重复文件）
- **AND** 设备B SHALL 收到成功响应后设置 `isUploaded = true`

#### Scenario: 并发上传控制
- **WHEN** 创建上传任务
- **THEN** 系统 SHALL 检查资产的 `isUploaded` 状态
- **AND** 如果 `isUploaded = true`，系统 SHALL 跳过创建任务
- **AND** 如果已有进行中的上传任务，系统 SHALL 不创建新任务
- **AND** 系统 SHALL 使用数据库唯一约束防止重复任务

