# 模块架构指南: `background_jobs` 框架

## 1. 愿景与核心理念

`background_jobs` 模块是本应用后台任务的统一处理中心。它的核心目标是提供一个**健壮、可扩展、易于理解**的框架，用于管理所有需要在后台执行的任务，无论是简单的周期性任务还是复杂的计算密集型作业。

**核心设计理念:**

*   **关注点分离 (SoC)**: 框架代码 (`core`) 与业务代码 (`impl`) 严格分离。框架只提供“能力”，业务负责“实现”。
*   **Isolate 即服务 (IaaS)**: 我们将后台 Isolate 视为一个共享的、强大的“计算服务器”。任何复杂的业务都应将其计算部分封装成一个“作业(Job)”，提交给这个服务，而不是自己管理 Isolate。
*   **清晰的边界与合约**: 通过明确的接口 (`BackgroundTask`, `IsolateTaskHandler`) 和数据模型，确保各组件之间的交互是可预测和低耦合的。

---

## 2. 架构深度解析

模块分为两大核心部分：`core` 和 `impl`。

```
lib/features/background_jobs
├── core/                  # 引擎室：提供通用框架
└── impl/                  # 业务车间：存放具体实现
```

### 2.1 `core` - 引擎室

`core` 目录提供了两项核心的通用服务：

#### A. 简单后台任务框架 (基于 Workmanager)

*   **组件**:
    *   `contracts/background_task.dart`: 定义了 `BackgroundTask` 接口。任何希望被 `Workmanager` 调度的简单任务都必须实现它。
    *   `task_dispatcher.dart`: `Workmanager` 的**唯一入口点**。它像一个路由器，根据任务名称查找并执行对应的 `BackgroundTask` 实现。
*   **适用场景**: 周期性的、非紧急的、不涉及大量计算的任务。例如：每隔几小时检查一次更新、上报一次日志。

#### B. 通用 Isolate 作业服务

这是框架的真正核心，用于处理复杂任务。

*   **组件**:
    *   `isolate/isolate_job_manager.dart`: **(关键)** 这是一个单例服务，是主线程与后台 Isolate 交互的**唯一入口**。它负责：
        *   启动和销毁 `GenericIsolate`。
        *   提供 `submitJob()` 和 `executeJob()` 方法来发送作业。
        *   通过 `jobResultStream` 广播来自 Isolate 的所有结果和进度更新。
    *   `isolate/generic_isolate.dart`: 通用 Isolate 的入口点。它内部维护一个**任务处理器注册表**，接收 `IsolateJob`，分发给对应的 `Handler`，并将结果发回。
    *   `contracts/isolate_task_handler.dart`: 定义了 `IsolateTaskHandler` 接口。任何希望在 Isolate 中运行的业务逻辑，都必须实现这个接口。
    *   `isolate/models.dart`: 定义了主 Isolate 和后台 Isolate 之间通信的**通用语言**（`IsolateJob`, `IsolateJobResult`）。
*   **适用场景**: 任何可能阻塞 UI 线程的耗时操作。例如：
    *   大量文件的 I/O 操作（备份、压缩、加密）。
    *   复杂的数据对账和计算（如媒体库同步）。
    *   图像或视频处理。

### 2.2 `impl` - 业务车间

`impl` 下的每个子目录都是一个独立的业务功能。以 `media_sync` 为例，它展示了实现一个复杂后台任务的最佳实践：

*   `service/media_sync_service.dart`: **门面 (Facade)**。这是该功能对外的唯一入口，供 UI 层或其他服务调用。它将外部调用转换为对 `IsolateJobManager` 的作业提交。
*   `domain/`: **核心领域**。包含所有纯粹的业务逻辑，与外部框架无关。
    *   `orchestrator.dart`: **编排器**。业务流程的总指挥。
    *   `executor.dart`: **执行器**。负责具体的执行动作（如数据库写入）。
    *   `synchronizers/`: **数据源**。负责从各处（本地、云端）获取数据。
    *   `isolate_handler.dart`: **(关键)** 业务在 Isolate 中的**代理人**。它实现了 `IsolateTaskHandler` 接口，负责接收通用 `IsolateJob`，并调用 `Orchestrator` 来启动真正的业务流程。
*   `background/`: **适配器 (Adapter)**。如果这个业务需要被 `Workmanager` 触发，就在这里创建一个适配器，实现 `BackgroundTask` 接口。

---

## 3. 核心流程与图例说明

#### 流程图 A: UI 触发的复杂任务 (如手动同步)

```
[ UI Widget ]
      |
      1. call triggerFullSync()
      v
[ MediaSyncService (Facade) ]
      |
      2. submitJob('mediaSync', payload)
      v
[ IsolateJobManager (Singleton) ]
      |
      3. send(IsolateJob) to Isolate
      v
================= Isolate Boundary =================
      |
      v
[ genericIsolateEntrypoint ]
      |
      4. lookup handler for 'mediaSync'
      v
[ MediaSyncIsolateHandler ]
      |
      5. call orchestrator.handleCommand()
      v
[ MediaSyncOrchestrator ] <--> [ Executors, Synchronizers ]
      |
      6. (In Progress) send(SyncProgressUpdate) back to Main Thread
      |
================= Isolate Boundary =================
      |
      v
[ IsolateJobManager (Singleton) ]
      |
      7. broadcast(SyncProgressUpdate) via jobResultStream
      v
[ MediaSyncService (Facade) ]
      |
      8. update internal state stream
      v
[ UI Widget ] (Rebuilds with new state)
```

**流程解释**:

1.  **UI** 调用 `MediaSyncService` 提供的简洁接口。
2.  **Service** 将这个业务请求翻译成一个通用的 `IsolateJob`，通过 `IsolateJobManager` 提交。
3.  **Manager** 负责将这个作业发送到正在运行的后台 Isolate。
4.  **Isolate 入口** 像一个路由器，根据作业名称找到对应的业务处理器 (`MediaSyncIsolateHandler`)。
5.  **Isolate Handler** 作为业务代理，调用真正的业务核心 `Orchestrator`。
6.  **Orchestrator** 在执行过程中，可以随时通过 `SendPort` 发送进度更新消息。
7.  **Manager** 接收到来自 Isolate 的任何消息，并通过 `jobResultStream` 广播出去。
8.  **Service** 监听这个广播流，过滤出自己关心的消息，并更新自身的状态，最终驱动 UI 刷新。

---

## 4. 开发者实践指南：添加新任务

### 4.1 添加一个简单的后台任务

**场景**: 创建一个每 12 小时自动清理一次应用日志文件的简单任务。

#### 步骤 1: 创建业务实现

在 `impl/` 下创建 `log_cleanup` 目录和文件。

**`lib/features/background_jobs/impl/log_cleanup/cleanup_task.dart`**
```dart
import 'package:mobile/features/background_jobs/core/contracts/background_task.dart';

// 任务的唯一名称
const String logCleanupTaskName = "com.example.mobile.logCleanup";

class LogCleanupTask implements BackgroundTask {
  @override
  Future<bool> execute(Map<String, dynamic>? inputData) async {
    try {
      print('[LogCleanupTask] Starting log cleanup...');
      
      // --- 你的业务逻辑在这里 ---
      // 1. 找到日志目录
      // 2. 遍历文件，删除7天前的文件
      await Future.delayed(const Duration(seconds: 5)); // 模拟工作
      // --------------------------

      print('[LogCleanupTask] Log cleanup finished successfully.');
      return true; // 返回 true 表示成功
    } catch (e) {
      print('[LogCleanupTask] Error during log cleanup: $e');
      return false; // 返回 false 表示失败，Workmanager 可能会重试
    }
  }
}
```

#### 步骤 2: 注册任务

在 `core` 的分发器中注册你的任务。

**`lib/features/background_jobs/core/task_dispatcher.dart`**
```dart
// ... 其他 import
import 'package:mobile/features/background_jobs/impl/log_cleanup/cleanup_task.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  final Map<String, BackgroundTask> taskHandlers = {
    periodicCloudSyncTask: PeriodicSyncAdapter(),
    // === [在这里添加你的新任务] ===
    logCleanupTaskName: LogCleanupTask(),
  };

  Workmanager().executeTask((taskName, inputData) async {
    // ... 其余代码不变 ...
  });
}
```

#### 步骤 3: 调度任务

在应用启动的某个地方（例如 `main.dart` 或某个初始化服务中）进行调度。

**`lib/somewhere_in_your_app.dart`**
```dart
import 'package:workmanager/workmanager.dart';
import 'package:mobile/features/background_jobs/impl/log_cleanup/cleanup_task.dart';

void schedulePeriodicTasks() {
  Workmanager().registerPeriodicTask(
    "uniqueIdForLogCleanup", // Workmanager 需要的唯一 ID
    logCleanupTaskName,      // 我们在 dispatcher 中注册的任务名
    frequency: const Duration(hours: 12),
  );
}
```

**完成！** 你的简单后台任务现在已经集成到框架中了。

### 4.2 添加一个复杂的 Isolate 任务

**场景**: 使用 `background_downloader` 创建一个文件备份功能，用户可以选择一些文件，应用会在后台将它们上传到服务器。

#### 步骤 1: 创建业务目录和文件结构

```
impl/
└── file_backup/
    ├── domain/
    │   └── isolate_handler.dart  # 核心业务逻辑
    └── service/
        └── file_backup_service.dart # 对外的门面
```

#### 步骤 2: 实现 Isolate 业务逻辑

**`lib/features/background_jobs/impl/file_backup/domain/isolate_handler.dart`**
```dart
import 'dart:isolate';
import 'package:background_downloader/background_downloader.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/features/background_jobs/core/contracts/isolate_task_handler.dart';

// 定义作业的 Payload 模型，增强类型安全
class FileBackupPayload {
  final List<String> filePaths;
  FileBackupPayload(this.filePaths);
}

@injectable
class FileBackupIsolateHandler implements IsolateTaskHandler {
  // 任务的唯一名称
  static const String taskName = 'fileBackup';

  @override
  Future<void> initialize(SendPort mainSendPort) async {
    // 可以在这里初始化一些监听器等
    print('[FileBackupIsolateHandler] Initialized.');
  }

  @override
  Future<dynamic> handle(dynamic payload) async {
    if (payload is! FileBackupPayload) {
      throw ArgumentError('Payload must be of type FileBackupPayload');
    }

    print('[FileBackupIsolateHandler] Starting backup for ${payload.filePaths.length} files.');
    
    final tasks = <UploadTask>[];
    for (final filePath in payload.filePaths) {
      final task = UploadTask(
        url: 'https://your-server.com/upload', // 你的上传端点
        filePath: filePath,
        headers: {'Authorization': 'Bearer your-token'},
        // 可以在 'post' 中添加额外字段
        // post: {'metadata': '...'}, 
      );
      tasks.add(task);
    }

    // `enqueue` 方法会立即返回，并将任务交给 background_downloader 的原生端处理
    // 这不会阻塞我们的 Isolate
    await FileDownloader().enqueue(tasks);

    print('[FileBackupIsolateHandler] All backup tasks have been enqueued.');
    
    // 我们可以立即返回一个确认消息
    return 'Successfully enqueued ${tasks.length} files for backup.';
  }

  @override
  Future<void> dispose() async {
    print('[FileBackupIsolateHandler] Disposed.');
  }
}
```

#### 步骤 3: 注册 Isolate 处理器

**`lib/features/background_jobs/core/isolate/generic_isolate.dart`**
```dart
// ... 其他 import
import 'package:mobile/features/background_jobs/impl/file_backup/domain/isolate_handler.dart';

void genericIsolateEntrypoint(Map<String, dynamic> initialData) async {
  // ...
  try {
    // ...
    final Map<String, IsolateTaskHandler> handlers = {
      MediaSyncIsolateHandler.taskName: getIt<MediaSyncIsolateHandler>(),
      // === [在这里注册你的新 Handler] ===
      FileBackupIsolateHandler.taskName: getIt<FileBackupIsolateHandler>(),
    };
    // ... 其余代码不变 ...
  } catch (e, s) {
    // ...
  }
}
```
*(别忘了在依赖注入配置中注册 `FileBackupIsolateHandler` 为 `@injectable`)*

#### 步骤 4: 创建门面 Service

**`lib/features/background_jobs/impl/file_backup/service/file_backup_service.dart`**
```dart
import 'package:injectable/injectable.dart';
import 'package:mobile/features/background_jobs/core/isolate/isolate_job_manager.dart';
import 'package:mobile/features/background_jobs/impl/file_backup/domain/isolate_handler.dart';

@lazySingleton
class FileBackupService {
  final IsolateJobManager _jobManager;

  FileBackupService(this._jobManager);

  /// 触发文件备份
  /// 返回 Isolate 的确认消息
  Future<String> backupFiles(List<String> filePaths) async {
    if (filePaths.isEmpty) {
      return "No files to backup.";
    }

    // 使用 executeJob，它会等待 Isolate 返回最终结果
    final result = await _jobManager.executeJob(
      FileBackupIsolateHandler.taskName,
      payload: FileBackupPayload(filePaths), // 传递类型安全的 payload
    );

    return result.toString();
  }

  // 你还可以监听 background_downloader 的全局进度
  // Stream<TaskProgressUpdate> get backupProgressStream => FileDownloader().updates;
}
```

#### 步骤 5: 从 UI 调用

```dart
// 在你的 UI Widget 中

// 1. 获取 Service 实例
final backupService = getIt<FileBackupService>();

// 2. 在按钮点击等事件中调用
onPressed: () async {
  // 假设你通过 file_picker 等插件获取了文件路径
  final List<String> filesToBackup = ['/path/to/image.jpg', '/path/to/video.mp4'];
  
  print("Starting backup...");
  final confirmationMessage = await backupService.backupFiles(filesToBackup);
  print("Backup Result: $confirmationMessage");
  
  // ignore: use_build_context_synchronously
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(confirmationMessage)),
  );
}
```

**完成！** 您现在拥有一个功能齐全、在独立 Isolate 中运行、利用原生后台下载插件、并且与主应用完全解耦的复杂后台任务。它完美地复用了 `IsolateJobManager`，而无需编写任何 Isolate 管理的模板代码。  


### 4.3 后台自动化任务

。将复杂任务（如文件备份）从“手动触发”变为“自动触发”，完美地展示了我们 `background_jobs` 框架中**两个核心服务协同工作**的强大能力。

我们将结合**简单后台任务框架 (Workmanager)** 和 **通用 Isolate 作业服务** 来实现这个需求。

---

#### 自动文件备份：架构思路

自动备份的本质是：**由一个简单的、定时的“触发器”去唤醒一个复杂的、耗时的“执行器”**。

*   **触发器**: 我们需要一个能**在应用未打开时**，按照一定规则（例如：每天凌晨2点、仅在Wi-Fi下、仅在充电时）唤醒应用的东西。这正是 `Workmanager` 的职责。
*   **执行器**: 文件备份本身是耗时的I/O密集型任务，不应在 `Workmanager` 提供的短暂后台执行窗口中直接完成，而是应该被提交到我们健壮的 `Isolate` 服务中去执行。

因此，我们的实现路径非常清晰：

1.  创建一个**适配器 (Adapter)**，它本身是一个简单的 `BackgroundTask`，可以被 `Workmanager` 调度。
2.  这个适配器的唯一职责是：**决定需要备份哪些文件，然后将备份作业提交给 `IsolateJobManager`**。
3.  `Isolate` 接收到作业后，执行实际的备份逻辑（使用 `background_downloader`）。

这样，`Workmanager` 只负责“拉响闹钟”，而真正的重活累活全部交给了 `Isolate`，各司其职，完美解耦。

---

#### 实践指南：实现自动文件备份

我们将基于上一节“手动备份”的代码进行扩展。

##### 步骤 1: 创建自动备份的触发规则和业务逻辑

首先，我们需要一个地方来决定“自动备份应该备份什么？”。这通常涉及到查询数据库，找出那些被标记为“待备份”或在某个时间点之后新增的文件。

为了示例简单，我们假设有一个 `DatabaseService`，它有一个方法 `getFilesToAutoBackup()` 可以返回需要备份的文件路径列表。

##### 步骤 2: 创建适配器 (Adapter)

这是连接 `Workmanager` 和 `Isolate` 服务的关键桥梁。

在 `impl/file_backup/` 目录下，创建一个新的 `background/` 目录。

**`lib/features/background_jobs/impl/file_backup/background/auto_backup_adapter.dart`**
```dart
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/features/background_jobs/core/contracts/background_task.dart';
import 'package:mobile/features/background_jobs/core/isolate/isolate_job_manager.dart';
import 'package:mobile/features/background_jobs/impl/file_backup/domain/isolate_handler.dart';

// 任务的唯一名称
const String autoBackupTaskName = "com.example.mobile.autoFileBackup";

/// 这个适配器的职责是：
/// 1. 被 Workmanager 定时唤醒。
/// 2. 决定需要备份哪些文件。
/// 3. 将一个 "fileBackup" 作业提交给 IsolateJobManager。
/// 4. （可选）等待 Isolate 确认任务已接收，然后向 Workmanager 报告成功。
class AutoBackupAdapter implements BackgroundTask {
  final _log = Logger('AutoBackupAdapter');

  @override
  Future<bool> execute(Map<String, dynamic>? inputData) async {
    _log.info('Automatic backup task triggered by Workmanager.');

    final jobManager = getIt<IsolateJobManager>();

    try {
      // --- 核心业务逻辑在这里 ---
      // 1. 从数据库或其他服务获取需要备份的文件列表
      // 注意：这里不能是UI层的服务，必须是可以在后台独立运行的数据服务
      // final dbService = getIt<DatabaseService>();
      // final List<String> filesToBackup = await dbService.getFilesToAutoBackup();

      // [为了示例，我们使用硬编码的列表]
      final List<String> filesToBackup = [
        '/path/to/auto_backup_file_1.jpg',
        '/path/to/auto_backup_file_2.png',
      ];
      _log.info('Found ${filesToBackup.length} files to backup.');

      if (filesToBackup.isEmpty) {
        _log.info('No new files to backup. Task finished successfully.');
        return true; // 没有文件也算成功
      }

      // 2. 确保 Isolate 服务已启动
      await jobManager.start();

      // 3. 将文件备份作业提交给 Isolate。
      // 我们使用 executeJob，它会等待 Isolate 返回确认消息。
      // 这可以确保在 Workmanager 任务结束前，Isolate 已经接手了工作。
      final confirmation = await jobManager.executeJob(
        FileBackupIsolateHandler.taskName,
        payload: FileBackupPayload(filesToBackup),
      ).timeout(const Duration(minutes: 1)); // 设置一个合理的超时

      _log.info('Isolate confirmed job reception: "$confirmation". Task finished successfully.');

      return true; // 向 Workmanager 报告成功

    } catch (e, s) {
      _log.severe('An error occurred during automatic backup task.', e, s);
      return false; // 报告失败，Workmanager 可能会在未来重试
    } finally {
      // 在一个由 Workmanager 触发的、生命周期短暂的任务中，
      // 执行完后可以考虑关闭 Isolate 以释放资源。
      // 但如果 Isolate 可能还在被其他部分使用，则不应关闭。
      // 这是一个需要根据应用具体情况决定的策略。
      // 为安全起见，通常只有在确定没有其他活动时才关闭。
      // jobManager.dispose(); 
    }
  }
}
```

##### 步骤 3: 注册新的后台任务

和简单任务一样，我们需要在 `task_dispatcher` 中注册这个新的适配器。

**`lib/features/background_jobs/core/task_dispatcher.dart`**
```dart
// ... 其他 import
import 'package:mobile/features/background_jobs/impl/file_backup/background/auto_backup_adapter.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  final Map<String, BackgroundTask> taskHandlers = {
    periodicCloudSyncTask: PeriodicSyncAdapter(),
    logCleanupTaskName: LogCleanupTask(),
    // === [在这里添加你的自动备份任务] ===
    autoBackupTaskName: AutoBackupAdapter(),
  };

  Workmanager().executeTask((taskName, inputData) async {
    // 确保在后台任务开始时初始化依赖注入
    await configureDependencies();

    final handler = taskHandlers[taskName];
    // ... 其余代码不变 ...
  });
}
```
**重要**: `callbackDispatcher` 是在一个新的 Isolate 中被 `Workmanager` 唤醒的，所以它需要**独立地初始化依赖注入** (`await configureDependencies()`)，这样 `AutoBackupAdapter` 才能通过 `getIt` 获取到 `IsolateJobManager` 的实例。

##### 步骤 4: 调度自动任务

现在，在应用中的某个地方（比如用户在设置页面开启了“自动备份”开关时），调度这个任务。

```dart
import 'package:workmanager/workmanager.dart';
import 'package:mobile/features/background_jobs/impl/file_backup/background/auto_backup_adapter.dart';

void enableAutoBackup() {
  Workmanager().registerPeriodicTask(
    "uniqueIdForAutoBackup",   // Workmanager 需要的唯一 ID
    autoBackupTaskName,        // 我们在 dispatcher 中注册的任务名
    frequency: const Duration(days: 1), // 例如每天一次
    initialDelay: const Duration(minutes: 5), // 5分钟后开始第一次
    constraints: Constraints(
      networkType: NetworkType.unmetered, // 仅在 Wi-Fi 下
      requiresCharging: true,              // 仅在充电时
    ),
  );
  print("Automatic backup has been scheduled.");
}

void disableAutoBackup() {
    Workmanager().cancelByUniqueName("uniqueIdForAutoBackup");
    print("Automatic backup has been cancelled.");
}
```

##### 总结与流程回顾

至此，一个健壮的自动备份功能已经完成。让我们回顾一下它的完整生命周期：

1.  **调度**: 用户开启自动备份，`Workmanager` 接到指令，开始根据设定的频率和约束（每天、Wi-Fi、充电）等待时机。

2.  **唤醒**: 在未来的某个时间点（例如凌晨2点，手机正在充电并连接Wi-Fi），`Workmanager` 唤醒应用后台，执行 `callbackDispatcher`。

3.  **分发**: `callbackDispatcher` 找到并实例化 `AutoBackupAdapter`，调用其 `execute` 方法。

4.  **决策与委托**: `AutoBackupAdapter` 开始执行。它查询数据库，发现有3个新文件需要备份。它**不会自己去上传**，而是将这3个文件的路径打包成一个 `FileBackupPayload`，然后调用 `IsolateJobManager.executeJob()`，将这个“重活”委托出去。

5.  **Isolate 接手**: `IsolateJobManager` 将作业发送到后台 `Isolate`。`GenericIsolate` 接收到后，找到 `FileBackupIsolateHandler` 并调用它的 `handle` 方法。

6.  **执行**: `FileBackupIsolateHandler` 开始调用 `background_downloader` 将这3个文件加入上传队列。`background_downloader` 会利用原生能力在后台进行网络传输。`handle` 方法在任务入队后，立即返回一个确认消息。

7.  **确认与休眠**: `AutoBackupAdapter` 在 `executeJob` 方法中收到了 Isolate 返回的确认消息。它知道任务已经被成功“接手”，于是打印一条日志，并向 `Workmanager` 返回 `true`。`Workmanager` 任务结束，应用后台再次进入休眠状态。

8.  **真正的后台工作**: 此时，即使 `Workmanager` 任务已经结束，`background_downloader` 的原生部分仍然在后台默默地上传文件。

这个流程完美地利用了 `Workmanager` 的**定时唤醒能力**和我们自定义 Isolate 框架的**复杂任务处理能力**，实现了功能的高内聚和低耦合。
