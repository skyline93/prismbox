
### **post组件迁移后的重构方案**

当前的核心任务是将分散的逻辑（来自MVP的`Provider`和`Repository`）**整合**进现有的 `group` 模块中，并让新的UI组件（`PostWidget`）消费主项目统一的数据模型，最终完成页面的替换。

我们将遵循以下步骤：
1.  **统一数据模型**：废弃临时的`PostModel`，创建符合主项目规范的领域实体。
2.  **统一数据仓库**：将帖子相关的逻辑合并到`GroupRepository`中。
3.  **统一状态管理**：将帖子流和发布的状态逻辑全部整合进`GroupFeedViewModel`。
4.  **连接UI与新逻辑**：重构`group_feed_page.dart`，让它使用新的ViewModel状态和`PostWidget`。
5.  **清理冗余代码**。

---

### **详细实施方案**

#### **第一阶段：统一数据层 (Domain & Data)**

##### **步骤 1.1: 创建权威的Feed实体模型**

*   **目标**：创建一个单一、权威的数据模型 `GroupFeedItemEntity` 来驱动新的UI，并最终删除临时的 `post_model.dart`。
*   **操作**：
    1.  **分析**：打开并比较这三个文件，明确一个Feed卡片需要的所有数据字段（发帖人头像、昵称、内容、图片、时间、点赞数、评论数等）。
        *   `domain/entities/post_model.dart` (MVP的临时模型)
        *   `data/models/group/group_models.dart` (可能包含帖子内容)
        *   `domain/entities/unified_media_entity.dart` (可能包含图片信息)
    2.  **创建新文件**：在 `lib/domain/entities/` 目录下，创建一个新文件 `group_feed_item_entity.dart`。
    3.  **定义实体**：使用 `freezed` 在 `group_feed_item_entity.dart` 中定义一个新的实体类 `GroupFeedItemEntity`，它应该包含从上述分析中整合的所有字段。

##### **步骤 1.2: 合并 Repository 逻辑**

*   **目标**：将数据获取和提交的逻辑统一到 `GroupRepository` 中，并删除 `posts_repository.dart`。
*   **操作**：
    1.  **查看接口**：打开 `domain/repositories/posts_repository.dart`，查看其中定义的方法（例如 `getPosts`, `createPost`）。
    2.  **修改接口**：打开 `domain/repositories/group_repository.dart`，将上述方法（调整返回类型为新的 `GroupFeedItemEntity`）添加进去。
        *   例如，添加 `Future<List<GroupFeedItemEntity>> getGroupFeed(String groupId);`
        *   以及 `Future<void> createPostInGroup(String groupId, String content, List<Image> attachments);`
    3.  **实现逻辑**：打开 `data/repositories/group_repository_impl.dart`，实现上述新添加的接口方法。这里的实现逻辑需要调用 `group_api_service.dart` 中的方法来与后端API交互。

#### **第二阶段：统一状态管理 (ViewModel)**

##### **步骤 2.1: 强化 `GroupFeedState`**

*   **目标**：更新 `GroupFeedState`，使其能够存储新的Feed列表数据、加载状态和错误信息。
*   **操作**：
    1.  **修改文件**：打开 `ui/group/viewmodels/group_feed_state.dart`。
    2.  **添加字段**：在 `@freezed` 类中，移除旧的与媒体网格相关的字段，添加新的字段，例如：
        *   `@Default([]) List<GroupFeedItemEntity> feedItems`
        *   `@Default(true) bool isLoading`
        *   `String? errorMessage`

##### **步骤 2.2: 整合 `GroupFeedViewModel`**

*   **目标**：将所有业务逻辑（加载、刷新、发布）集中到 `GroupFeedViewModel`，并删除临时的`posts_provider.dart`和`new_thread_provider.dart`。
*   **操作**：
    1.  **查看参考**：打开 `providers/posts_provider.dart` 和 `providers/new_thread_provider.dart`，理解它们内部的业务逻辑。
    2.  **修改文件**：打开 `ui/group/viewmodels/group_feed_viewmodel.dart`。
    3.  **注入依赖**：确保 `GroupRepository` 已经通过构造函数注入到这个ViewModel中。
    4.  **实现加载逻辑**：创建一个 `Future<void> fetchFeed()` 方法。在此方法中，调用 `groupRepository.getGroupFeed()`，并根据结果更新 `state`（更新`feedItems`列表，`isLoading`设为`false`）。
    5.  **实现发布逻辑**：创建一个 `Future<void> createNewPost(...)` 方法。此方法接收发布所需的数据（内容、图片等），调用 `groupRepository.createPostInGroup()`，发布成功后，再调用 `fetchFeed()` 来刷新整个列表。

#### **第三阶段：UI 链接与重构**

##### **步骤 3.1: 适配 `PostWidget`**

*   **目标**：让 `PostWidget` 使用新的 `GroupFeedItemEntity` 数据模型。
*   **操作**：
    1.  **修改文件**：打开 `ui/group/widgets/feed_card/post_widget.dart`。
    2.  **修改构造函数**：将其构造函数的参数类型从 `PostModel` 更改为 `GroupFeedItemEntity`。
    3.  **级联修改**：相应地调整 `post_widget.dart` 内部及其子组件（`post_header.dart`, `post_content.dart` 等）获取数据的方式，确保它们都能正确显示 `GroupFeedItemEntity` 中的数据。

##### **步骤 3.2: 核心页面重构 - `group_feed_page.dart`**

*   **目标**：将页面的主体替换为由`PostWidget`组成的列表，并由`GroupFeedViewModel`驱动。
*   **操作**：
    1.  **修改文件**：打开 `ui/group/pages/group_feed_page.dart`。
    2.  **监听状态**：确保页面的 `build` 方法正在正确地监听 `groupFeedViewModelProvider` 的状态。
    3.  **替换主体**：
        *   找到页面主体部分的旧 `GridView` 或 `ListView`。
        *   将其**完全替换**为一个新的 `ListView.builder`。
        *   `itemCount` 来源于 `state.feedItems.length`。
        *   `itemBuilder` 在每个列表项中返回一个 `PostWidget(item: state.feedItems[index])`。
        *   根据 `state.isLoading` 和 `state.errorMessage` 来显示加载指示器或错误提示。
    4.  **连接发布功能**：
        *   找到页面上的发布按钮（例如 `FloatingActionButton`）。
        *   在其 `onPressed` 事件中，调用 `showModalBottomSheet` 来显示 `new_thread_sheet.dart`。
        *   将 `NewThreadSheet` 的发布回调连接到 `groupFeedViewModel.createNewPost(...)` 方法。

#### **第四阶段：清理工作**

##### **步骤 4.1: 删除冗余文件**

*   **目标**：在确认所有功能正常工作后，保持项目代码的整洁。
*   **操作**：
    1.  **安全删除以下文件和目录**：
        *   `domain/entities/post_model.dart`
        *   `domain/entities/reply_permission.dart`
        *   `domain/repositories/posts_repository.dart`
        *   `providers/posts_provider.dart`
        *   `providers/new_thread_provider.dart`
        *   `providers/new_thread_provider.g.dart`
        *   `ui/group/widgets/group_media_grid_item.dart` (旧的网格项UI)
    2.  **代码生成**：如果删除了任何 `freezed` 或 `provider` 文件，记得再次运行 `build_runner` 命令来清理生成的代码。

完成以上所有步骤后，你的重构就大功告成。你将拥有一个结构清晰、数据流统一、易于维护的全新圈子Feed页面。
