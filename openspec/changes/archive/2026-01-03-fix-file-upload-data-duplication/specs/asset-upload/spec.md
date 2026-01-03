## MODIFIED Requirements

### Requirement: 资产上传 - 后端计算 Hash

系统 SHALL 在上传资产时，由后端统一计算文件 hash，前端不再计算或提供 hash。

#### Scenario: 前端不计算 hash
- **WHEN** 前端准备上传资产
- **THEN** 系统 SHALL 不计算文件 hash
- **AND** 系统 SHALL 不在上传请求中包含 `hash` 字段
- **AND** 系统 SHALL 将文件直接上传到服务器

#### Scenario: 后端计算 hash
- **WHEN** 后端接收上传请求
- **THEN** 后端 SHALL 从文件流计算 hash（使用 MD5 算法）
- **AND** 后端 SHALL 使用计算得到的 hash 构建存储 key
- **AND** 后端 SHALL 使用计算得到的 hash 创建媒体记录
- **AND** 后端 SHALL 不进行秒传检查（需要先读取文件才能计算 hash）

#### Scenario: 文件流处理
- **WHEN** 后端需要计算 hash 且同时需要存储文件
- **THEN** 后端 SHALL 处理文件流的重复读取需求
- **AND** 系统 SHALL 确保计算 hash 后文件流可以用于存储
- **AND** 系统 SHALL 使用高效的文件流复用方案（临时文件）
- **AND** 系统 SHALL 确保存储层接收到的是完整的、未重复的文件数据流
- **AND** 系统 SHALL 直接传递文件数据流给存储层，不进行数据组合或重复

