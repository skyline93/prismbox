# Change: 添加圈子功能

## Why

用户需要创建和管理圈子（群组），以便与朋友、家人或团队成员分享照片和视频。当前系统缺少圈子相关的移动端 UI 和完整的数据同步功能。

需要实现的核心功能：
- **创建圈子**：用户可以创建新圈子，设置名称和描述
- **圈子列表**：查看我创建和加入的所有圈子
- **圈子主页**：查看圈子信息、成员列表和 Feed 流
- **成员管理**：邀请成员、查看成员列表、移除成员
- **在线访问**：完全依赖后端 API，不存储到本地数据库（预留后续缓存优化）

## What Changes

### 移动端 UI 层
- **创建圈子页面**：输入圈子名称和描述，可选上传封面图
- **圈子列表页面**：展示我加入的所有圈子，支持创建新圈子入口
- **圈子主页**：展示圈子信息卡片、Feed 流、成员列表
- **成员管理页面**：查看成员列表、邀请成员、移除成员
- **UI 组件**：圈子卡片、圈子信息卡片、成员列表组件等

### 移动端数据层
- **圈子数据模型**：Group、GroupMember 等实体（仅用于 API 响应解析）
- **圈子服务**：GroupService，封装业务逻辑和 API 调用
- **状态管理**：使用 Riverpod Provider 管理页面状态（内存中）

### 移动端网络层
- **API 客户端**：封装圈子相关 API 调用
- **错误处理**：统一的错误处理和重试机制

### 路由配置
- **路由定义**：添加圈子相关路由（创建圈子、圈子列表、圈子主页、成员管理）

## Impact

- **新增文件**：
  - `mobile/lib/presentation/pages/groups/` - 圈子相关页面
  - `mobile/lib/presentation/widgets/groups/` - 圈子相关组件
  - `mobile/lib/data/models/group/` - 圈子数据模型（仅用于 API 响应）
  - `mobile/lib/services/group/` - 圈子服务
  - `mobile/lib/providers/group/` - 圈子 Provider（内存状态管理）
- **受影响文件**：
  - `mobile/lib/presentation/routing/app_router.dart` - 添加路由
  - `mobile/lib/infrastructure/network/` - 添加 API 客户端
- **受影响规范**：
  - `openspec/specs/group/spec.md` - 新增圈子功能规范
- **向后兼容性**：
  - 完全向后兼容，不影响现有功能

