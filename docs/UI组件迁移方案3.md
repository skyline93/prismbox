
### **重构方案文件梳理**

以下是根据您提供的重构步骤和代码目录结构，梳理出的需要**查看**、**修改**、**新增**及最终**删除**的文件清单。

---

### **第一阶段：统一数据层 (Domain & Data)**

#### **需要查看的文件 (用于分析和参考)**

1.  `lib/domain/entities/post_model.dart`: 查看临时的 `PostModel` 的具体字段，这是定义新模型的主要参考。
2.  `lib/data/models/group/group_models.dart`: 查看现有的 `Group` 相关模型，确认是否有可以复用或需要整合的帖子相关字段。
3.  `lib/domain/entities/unified_media_entity.dart`: 查看媒体实体，了解图片、视频等附件的数据结构，以便在新模型中正确引用。
4.  `lib/domain/repositories/posts_repository.dart`: 查看临时的 `Repository` 接口，明确需要迁移哪些数据获取和提交的方法（如 `getPosts`, `createPost`）。
5.  `lib/data/services/group_api_service.dart`: 查看与后端API交互的服务，了解获取圈子数据和发帖的接口是如何调用的，这是在 `Repository` 实现中需要用到的。

#### **需要修改的文件**

1.  `lib/domain/repositories/group_repository.dart`: **修改接口定义**。将 `posts_repository.dart` 中的方法（例如 `getPosts`, `createPost`）添加到此文件中，并更新其返回值为新的 `GroupFeedItemEntity`。
2.  `lib/data/repositories/group_repository_impl.dart`: **修改具体实现**。实现上一条中新增的接口方法，调用 `group_api_service.dart` 来完成实际的数据请求。

#### **需要新增的文件**

1.  `lib/domain/entities/group_feed_item_entity.dart`: **新增核心实体模型**。这个新文件将使用 `freezed` 定义统一的 `GroupFeedItemEntity`，它将包含一个帖子在Feed流中展示所需的所有字段。

---

### **第二阶段：统一状态管理 (ViewModel)**

#### **需要查看的文件 (用于分析和参考)**

1.  `lib/providers/posts_provider.dart`: 查看旧的帖子流状态管理逻辑，理解其如何加载和管理帖子列表。
2.  `lib/providers/new_thread_provider.dart`: 查看旧的发布帖子状态管理逻辑，理解其如何处理用户输入、调用API以及管理发布状态。

#### **需要修改的文件**

1.  `lib/ui/group/viewmodels/group_feed_state.dart`: **修改状态类**。移除旧的与媒体网格相关的字段，添加用于存储 `List<GroupFeedItemEntity>`、加载状态 `isLoading` 和错误信息 `errorMessage` 的新字段。
2.  `lib/ui/group/viewmodels/group_feed_viewmodel.dart`: **修改ViewModel**。
    *   注入 `GroupRepository`。
    *   实现 `fetchFeed()` 方法，用于调用 `Repository` 获取帖子列表并更新 `GroupFeedState`。
    *   实现 `createNewPost()` 方法，用于调用 `Repository` 发布新帖子，并在成功后刷新Feed列表。

---

### **第三阶段：UI 链接与重构**

#### **需要查看的文件 (用于分析和参考)**

1.  `lib/ui/group/pages/new_thread_sheet.dart`: 查看发布帖子的UI组件，了解如何调用其发布回调并传递数据给 `ViewModel`。

#### **需要修改的文件**

1.  `lib/ui/group/widgets/feed_card/post_widget.dart`: **修改核心UI组件**。将其构造函数的参数类型从临时的 `PostModel` 更改为新的 `GroupFeedItemEntity`。
2.  **`post_widget.dart` 的所有子组件**:
    *   `lib/ui/group/widgets/feed_card/post_header.dart`
    *   `lib/ui/group/widgets/feed_card/post_content.dart`
    *   `lib/ui/group/widgets/feed_card/post_image_carousel.dart`
    *   `lib/ui/group/widgets/feed_card/post_stats.dart`
    *   `lib/ui/group/widgets/feed_card/post_actions.dart`
    *   **级联修改**：由于父组件 `PostWidget` 的数据模型发生变化，所有消费该模型数据的子组件都需要同步更新，以从 `GroupFeedItemEntity` 中获取数据。
3.  `lib/ui/group/pages/group_feed_page.dart`: **修改核心页面**。
    *   确保页面正确监听 `groupFeedViewModelProvider` 的状态。
    *   将页面的旧 `GridView` **完全替换**为新的 `ListView.builder`。
    *   `ListView.builder` 的 `itemBuilder` 将返回配置了新数据模型的 `PostWidget`。
    *   根据 `ViewModel` 的 `isLoading` 和 `errorMessage` 状态，显示加载中或错误提示。
    *   将发布按钮的逻辑连接到 `groupFeedViewModel.createNewPost()` 方法。

---

### **第四阶段：清理工作**

#### **需要删除的文件和目录**

在所有功能迁移并验证通过后，以下文件和相关生成文件 (`.g.dart`, `.freezed.dart`) 将被安全删除：

1.  `lib/domain/entities/post_model.dart`
2.  `lib/domain/entities/reply_permission.dart`
3.  `lib/domain/repositories/posts_repository.dart`
4.  `lib/providers/posts_provider.dart`
5.  `lib/providers/new_thread_provider.dart`
6.  `lib/providers/new_thread_provider.g.dart`
7.  `lib/ui/group/widgets/group_media_grid_item.dart`

梳理完以上文件清单后，就可以按照这个路线图进行精确、高效的代码重构了。
