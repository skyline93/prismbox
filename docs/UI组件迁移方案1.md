好的，我们来将整个重构方案拆解成一个更详细、更具可操作性的清单。

这个清单将按照实施顺序，明确指出每一步的目标、需要关注的文件以及具体要做的事情。

---

### **准备阶段：环境设置**

*   **目标**：确保工作环境隔离，便于版本控制和回滚。
*   **操作**：
    1.  从主分支（如 `main` 或 `develop`）创建一个新的功能分支。
        *   **Git 命令示例**: `git checkout -b feature/refactor-group-feed-ui`

---

### **第一阶段：UI组件物理迁移与适配**

#### **步骤 1.1：创建新的目录结构**

*   **目标**：为主项目中的新UI组件规划好存放位置，保持代码结构清晰。
*   **操作**：在主项目的 `lib/ui/group/` 目录下创建新的文件夹。
*   **涉及文件/目录（创建）**：
    *   `lib/ui/group/widgets/feed_card/`
    *   `lib/ui/group/features/new_post/`

#### **步骤 1.2：复制源文件**

*   **目标**：将MVP项目中的UI代码完整地复制到主项目中。
*   **操作**：执行文件复制操作。
*   **涉及文件（从MVP项目复制到主项目）**：
    *   **从** `MVP/lib/ui/widgets/` **到** `主项目/lib/ui/group/widgets/feed_card/`：
        *   `post_actions.dart`
        *   `post_content.dart`
        *   `post_header.dart`
        *   `post_image_carousel.dart`
        *   `post_stats.dart`
        *   `post_widget.dart`
    *   **从** `MVP/lib/ui/new_thread/` **到** `主项目/lib/ui/group/features/new_post/`：
        *   `models/reply_permission.dart` (及其所在目录)
        *   `new_thread_sheet.dart`
        *   `widgets/...` (该目录下的所有widget文件)

#### **步骤 1.3：修复导入路径**

*   **目标**：解决因文件位置改变导致的编译错误，让新文件能被项目识别。
*   **操作**：逐个打开新复制的文件，修改顶部的 `import` 语句。
*   **涉及文件（修改）**：
    *   `lib/ui/group/widgets/feed_card/` 目录下的所有 `.dart` 文件。
    *   `lib/ui/group/features/new_post/` 目录下的所有 `.dart` 文件。
    *   **检查点**：此时，项目应该能够编译通过，尽管新UI还未被使用。

#### **步骤 1.4：UI样式统一**

*   **目标**：确保新UI组件的视觉风格（颜色、字体、间距等）与主项目完全一致。
*   **操作**：替换硬编码的样式值为项目主题 `Theme.of(context)` 中的定义。
*   **涉及文件（修改）**：
    *   再次检查 `lib/ui/group/widgets/feed_card/` 和 `lib/ui/group/features/new_post/` 下的所有UI文件。
*   **涉及文件（查看参考）**：
    *   `lib/main.dart`：通常在这里定义了全局的 `ThemeData`，是查找颜色和文本样式的起点。

---

### **第二阶段：数据模型与状态管理对接**

#### **步骤 2.1：定义Feed流的统一数据模型**

*   **目标**：创建一个专为新UI服务的数据实体，作为连接后端数据和前端UI的桥梁。
*   **操作**：分析 `PostModel` 和主项目的 `UnifiedMediaEntity`，设计一个新的 `freezed` 实体。
*   **涉及文件（查看参考）**：
    *   MVP项目的 `lib/data/post_model.dart`
    *   主项目的 `lib/domain/entities/unified_media_entity.dart`
*   **涉及文件（创建）**：
    *   `lib/domain/entities/group_feed_item_entity.dart`
    *   **说明**：这个新文件将定义一个类，包含展示一个Feed卡片所需的所有字段（如用户信息、帖子内容、图片列表、点赞数、评论数等）。

#### **步骤 2.2：更新`GroupFeedState`**

*   **目标**：让状态管理对象能够持有新的Feed列表数据。
*   **操作**：在 `GroupFeedState` 中添加一个 `List<GroupFeedItemEntity>` 字段。
*   **涉及文件（修改）**：
    *   `lib/ui/group/viewmodels/group_feed_state.dart`
    *   (如果使用build_runner) 运行代码生成命令，更新 `group_feed_state.freezed.dart`

#### **步骤 2.3：改造`PostWidget`以消费新模型**

*   **目标**：让核心UI组件 `PostWidget` 能够识别并展示来自主项目的数据。
*   **操作**：修改 `PostWidget` 及其子组件的构造函数。
*   **涉及文件（修改）**：
    *   `lib/ui/group/widgets/feed_card/post_widget.dart`：将其构造函数的参数类型从 `PostModel` 改为 `GroupFeedItemEntity`。
    *   `post_header.dart`, `post_content.dart` 等子组件：相应地修改它们的参数，或者让它们直接从父级 `PostWidget` 接收处理好的单个数据（如 `String userName`）。

---

### **第三阶段：打通完整数据链路**

#### **步骤 3.1：确认Repository层能力**

*   **目标**：确保数据访问层有能力获取Feed流所需的数据。
*   **操作**：检查或添加获取圈子Feed数据的方法。
*   **涉及文件（查看/修改）**：
    *   **接口定义**: `lib/domain/repositories/group_repository.dart`
    *   **接口实现**: `lib/data/repositories/group_repository_impl.dart`
    *   **可能需要参考**: `lib/data/services/group_api_service.dart` (确认API是否支持)
    *   **检查点**：需要有一个类似 `Future<List<GroupFeedItemEntity>> getGroupFeed(String groupId)` 的方法。

#### **步骤 3.2：在ViewModel中实现数据加载逻辑**

*   **目标**：编写业务逻辑，从Repository获取数据并更新UI状态。
*   **操作**：注入Repository，实现 `fetchFeed` 方法。
*   **涉及文件（修改）**：
    *   `lib/ui/group/viewmodels/group_feed_viewmodel.dart`：
        1.  通过构造函数注入 `GroupRepository`。
        2.  添加 `Future<void> fetchFeed()` 方法，方法内调用 `repository.getGroupFeed()`。
        3.  获取数据成功后，用新数据更新 `state`；失败则更新 `state` 中的错误信息。

#### **步骤 3.3：重构`group_feed_page.dart`页面**

*   **目标**：用新的 `PostWidget` 列表替换掉旧的媒体网格，完成UI的最终呈现。
*   **操作**：修改页面的 `build` 方法，使用 `ListView.builder` 渲染 `PostWidget`。
*   **涉及文件（修改）**：
    *   `lib/ui/group/pages/group_feed_page.dart`：
        1.  监听 `GroupFeedViewModel` 的状态。
        2.  移除旧的 `GridView`。
        3.  添加 `ListView.builder`。
        4.  `itemCount` 设置为 `state.feedItems.length`。
        5.  `itemBuilder` 中返回 `PostWidget(item: state.feedItems[index])`。
        6.  处理加载中和错误状态的UI显示。

---

### **第四阶段：集成“发布新内容”功能**

#### **步骤 4.1：在页面添加入口点**

*   **目标**：提供一个用户可见的按钮来触发“发布”流程。
*   **操作**：在 `Scaffold` 中添加一个 `FloatingActionButton`。
*   **涉及文件（修改）**：
    *   `lib/ui/group/pages/group_feed_page.dart`：
        *   在 `Scaffold` 中添加 `floatingActionButton` 属性。
        *   在 `onPressed` 回调中，编写代码以弹出 `new_thread_sheet.dart` 定义的模态框。

#### **步骤 4.2：在ViewModel中添加发布逻辑**

*   **目标**：编写处理用户发布内容的业务逻辑。
*   **操作**：添加一个接收用户输入并调用Repository的方法。
*   **涉及文件（修改）**：
    *   `lib/ui/group/viewmodels/group_feed_viewmodel.dart`：
        1.  添加一个新方法，如 `Future<void> createNewPost(String text, List<Asset> images)`。
        2.  方法内部调用 `repository.createPost(...)`。
        3.  发布成功后，调用 `fetchFeed()` 刷新列表。

#### **步骤 4.3：连接UI与ViewModel的发布功能**

*   **目标**：将发布界面的用户操作与后端的业务逻辑连接起来。
*   **操作**：通过回调函数将 `NewThreadSheet` 的发布事件传递给ViewModel。
*   **涉及文件（修改）**：
    *   `lib/ui/group/features/new_post/new_thread_sheet.dart`：确保它有一个 `onPost` 回调函数。
    *   `lib/ui/group/pages/group_feed_page.dart`：在显示 `NewThreadSheet` 时，将其 `onPost` 回调指向 `groupFeedViewModel.createNewPost` 方法。

---

### **第五阶段：清理与收尾**

#### **步骤 5.1：更新依赖注入**

*   **目标**：如果ViewModel的创建方式或依赖发生变化，需更新依赖注入容器。
*   **操作**：检查 `service_locator` 或 `providers` 文件。
*   **涉及文件（查看/修改）**：
    *   `lib/core/service_locator.dart`
    *   `lib/group_providers.dart`

#### **步骤 5.2：移除废弃代码**

*   **目标**：保持代码库的整洁。
*   **操作**：安全地删除不再被引用的旧UI组件。
*   **涉及文件（删除）**：
    *   `lib/ui/group/widgets/group_media_grid_item.dart`
    *   **检查**：`group_feed_viewmodel.dart` 和 `group_feed_state.dart` 中任何只与旧网格布局相关的逻辑和状态也应一并删除。

执行完以上所有步骤，你的圈子Feed页面重构就完成了。这个详细的清单可以作为你的行动指南和检查列表。
