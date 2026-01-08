## 1. 创建数据模型

- [x] 1.1 创建 `mobile/lib/data/models/group/group.dart` 文件
- [x] 1.2 实现 `Group` 实体类，包含 uuid、name、description、coverMediaUuid、ownerId 等字段（仅用于 API 响应解析）
- [x] 1.3 创建 `mobile/lib/data/models/group/group_member.dart` 文件
- [x] 1.4 实现 `GroupMember` 实体类，包含 groupId、userId、role、joinedAt 等字段（仅用于 API 响应解析）
- [x] 1.5 创建 `mobile/lib/data/models/group/group_detail.dart` 文件
- [x] 1.6 实现 `GroupDetail` 实体类，包含圈子详情和统计信息（仅用于 API 响应解析）

## 2. 创建网络层

- [x] 4.1 创建 `mobile/lib/infrastructure/network/group_api_client.dart` 文件
- [x] 4.2 实现圈子相关 API 调用（创建、获取列表、获取详情、更新、加入、退出等）
- [x] 4.3 实现成员管理 API 调用（获取成员列表、创建邀请码、移除成员）
- [x] 4.4 实现错误处理和重试机制

## 3. 创建服务层

- [x] 3.1 创建 `mobile/lib/services/group/group_service.dart` 文件
- [x] 3.2 实现 `GroupService` 类，封装业务逻辑
- [x] 3.3 实现创建圈子方法（调用 API）
- [x] 3.4 实现获取我的圈子列表方法（直接调用 API）
- [x] 3.5 实现获取圈子详情方法（直接调用 API，包含成员统计）
- [x] 3.6 实现加入圈子方法（使用邀请码，直接调用 API）
- [x] 3.7 实现退出圈子方法（直接调用 API）
- [x] 3.8 实现错误处理和重试机制
- [x] 3.9 预留缓存接口（注释说明后续可添加缓存层）

## 4. 创建 Provider 层

- [x] 6.1 创建 `mobile/lib/providers/group/group_list_provider.dart` 文件
- [x] 6.2 实现 `groupListProvider`，管理圈子列表状态
- [x] 6.3 创建 `mobile/lib/providers/group/group_detail_provider.dart` 文件
- [x] 6.4 实现 `groupDetailProvider`，管理圈子详情状态
- [x] 6.5 创建 `mobile/lib/providers/group/group_members_provider.dart` 文件
- [x] 6.6 实现 `groupMembersProvider`，管理成员列表状态

## 5. 创建 UI 组件

- [x] 5.1 创建 `mobile/lib/presentation/widgets/groups/group_card.dart` 文件
- [x] 5.2 实现 `GroupCard` 组件，展示圈子卡片（封面、名称、成员数等）
- [x] 5.3 创建 `mobile/lib/presentation/widgets/groups/group_info_card.dart` 文件
- [x] 5.4 实现 `GroupInfoCard` 组件，展示圈子信息（封面、名称、描述、统计）
- [x] 5.5 创建 `mobile/lib/presentation/widgets/groups/member_list_item.dart` 文件
- [x] 5.6 实现 `MemberListItem` 组件，展示成员信息（头像、用户名、角色）

## 6. 创建页面

- [x] 6.1 创建 `mobile/lib/presentation/pages/groups/create_group_page.dart` 文件
- [x] 6.2 实现 `CreateGroupPage`，包含名称输入、描述输入、封面选择
- [x] 6.3 创建 `mobile/lib/presentation/pages/groups/group_list_page.dart` 文件
- [x] 6.4 实现 `GroupListPage`，展示圈子列表，支持创建新圈子入口
- [x] 6.5 创建 `mobile/lib/presentation/pages/groups/group_detail_page.dart` 文件
- [x] 6.6 实现 `GroupDetailPage`，展示圈子信息卡片和 Feed 流（Feed 流在帖子提案中实现）
- [x] 6.7 创建 `mobile/lib/presentation/pages/groups/group_members_page.dart` 文件
- [x] 6.8 实现 `GroupMembersPage`，展示成员列表，支持邀请和移除成员

## 7. 配置路由

- [x] 7.1 在 `app_router.dart` 中添加 `CreateGroupRoute`
- [x] 7.2 在 `app_router.dart` 中添加 `GroupListRoute`
- [x] 7.3 在 `app_router.dart` 中添加 `GroupDetailRoute`
- [x] 7.4 在 `app_router.dart` 中添加 `GroupMembersRoute`
