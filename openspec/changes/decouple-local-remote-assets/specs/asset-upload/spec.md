## ADDED Requirements

### Requirement: 资产上传

系统 SHALL 提供资产上传功能，将本地资产上传到服务器。上传功能 SHALL 基于 `isUploaded` 字段进行去重，不依赖 checksum 关联。

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

