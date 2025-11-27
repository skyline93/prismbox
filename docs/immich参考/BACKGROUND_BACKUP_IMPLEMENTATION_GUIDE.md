# 后台备份方案实现指南

本文档提供在相册应用中实现类似 Immich 后台备份方案的详细步骤和代码示例。

## 目录

1. [前置准备](#前置准备)
2. [项目结构](#项目结构)
3. [Pigeon 接口定义](#pigeon-接口定义)
4. [Flutter 侧实现](#flutter-侧实现)
5. [Android 侧实现](#android-侧实现)
6. [iOS 侧实现](#ios-侧实现)
7. [集成步骤](#集成步骤)
8. [测试与调试](#测试与调试)

---

## 前置准备

### 依赖包

在 `pubspec.yaml` 中添加以下依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 类型安全通信
  pigeon: ^20.0.0
  
  # 状态管理
  hooks_riverpod: ^2.4.0
  
  # 后台文件操作
  background_downloader: ^8.0.0
  
  # HTTP 客户端（支持取消）
  cancellation_token_http: ^1.0.0
  
  # 日志
  logging: ^1.2.0
```

### 开发依赖

```yaml
dev_dependencies:
  pigeon: ^20.0.0  # 用于代码生成
```

---

## 项目结构

建议的项目结构：

```
lib/
├── domain/
│   └── services/
│       └── background_worker.service.dart  # 后台服务实现
├── platform/
│   └── background_worker_api.g.dart       # Pigeon 生成的代码
└── providers/
    └── background_worker.provider.dart    # Riverpod 提供者

pigeon/
└── background_worker_api.dart             # Pigeon 接口定义

android/app/src/main/kotlin/
└── your/package/background/
    ├── BackgroundWorker.kt
    ├── BackgroundWorkerApiImpl.kt
    └── BackgroundWorker.g.kt              # Pigeon 生成的代码

ios/Runner/Background/
├── BackgroundWorker.swift
├── BackgroundWorkerApiImpl.swift
└── BackgroundWorker.g.swift              # Pigeon 生成的代码
```

---

## Pigeon 接口定义

### 1. 创建接口定义文件

创建 `pigeon/background_worker_api.dart`：

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/background_worker_api.g.dart',
    swiftOut: 'ios/Runner/Background/BackgroundWorker.g.swift',
    kotlinOut: 'android/app/src/main/kotlin/your/package/background/BackgroundWorker.g.kt',
    kotlinOptions: KotlinOptions(package: 'your.package.background'),
  ),
)

// 配置类
class BackgroundWorkerSettings {
  final bool requiresCharging;
  final int minimumDelaySeconds;

  const BackgroundWorkerSettings({
    required this.requiresCharging,
    required this.minimumDelaySeconds,
  });
}

// 前台 API（从 Flutter 调用原生）
@HostApi()
abstract class BackgroundWorkerFgHostApi {
  void enable();
  void disable();
  void configure(BackgroundWorkerSettings settings);
  void saveNotificationMessage(String title, String body);
}

// 后台 API（从原生调用 Flutter）
@HostApi()
abstract class BackgroundWorkerBgHostApi {
  void onInitialized();
  void close();
}

// Flutter API（从原生调用 Flutter）
@FlutterApi()
abstract class BackgroundWorkerFlutterApi {
  @async
  void onAndroidUpload();
  
  @async
  void onIosUpload(bool isRefresh, int? maxSeconds);
  
  @async
  void cancel();
}
```

### 2. 生成代码

运行以下命令生成代码：

```bash
flutter pub run pigeon --input pigeon/background_worker_api.dart
```

---

## Flutter 侧实现

### 1. 后台服务实现

创建 `lib/domain/services/background_worker.service.dart`：

```dart
import 'dart:async';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/platform/background_worker_api.g.dart';
import 'package:logging/logging.dart';

// 前台服务（在主应用中调用）
class BackgroundWorkerFgService {
  final BackgroundWorkerFgHostApi _api;
  
  BackgroundWorkerFgService(this._api);
  
  Future<void> enable() => _api.enable();
  Future<void> disable() => _api.disable();
  
  Future<void> configure({
    int? minimumDelaySeconds,
    bool? requireCharging,
  }) {
    return _api.configure(BackgroundWorkerSettings(
      minimumDelaySeconds: minimumDelaySeconds ?? 5,
      requiresCharging: requireCharging ?? false,
    ));
  }
  
  Future<void> saveNotificationMessage(String title, String body) {
    return _api.saveNotificationMessage(title, body);
  }
}

// 后台服务（在后台任务中运行）
class BackgroundWorkerBgService extends BackgroundWorkerFlutterApi {
  final Logger _logger = Logger('BackgroundWorkerBgService');
  final BackgroundWorkerBgHostApi _backgroundHostApi;
  bool _isCleanedUp = false;
  
  BackgroundWorkerBgService()
      : _backgroundHostApi = BackgroundWorkerBgHostApi() {
    BackgroundWorkerFlutterApi.setUp(this);
  }
  
  Future<void> init() async {
    try {
      // 初始化数据库、服务等
      await _initializeServices();
      
      // 通知原生层初始化完成
      await _backgroundHostApi.onInitialized();
    } catch (error, stack) {
      _logger.severe("初始化失败", error, stack);
      await _backgroundHostApi.close();
    }
  }
  
  @override
  Future<void> onAndroidUpload() async {
    _logger.info('Android 后台任务开始');
    try {
      // 执行备份逻辑
      await _performBackup();
    } catch (error, stack) {
      _logger.severe("备份失败", error, stack);
    } finally {
      await _cleanup();
    }
  }
  
  @override
  Future<void> onIosUpload(bool isRefresh, int? maxSeconds) async {
    _logger.info('iOS 后台任务开始');
    try {
      final timeout = isRefresh 
          ? const Duration(seconds: 5) 
          : Duration(seconds: maxSeconds ?? 60);
      
      await _performBackup().timeout(timeout, onTimeout: () {
        _logger.warning("任务超时");
      });
    } catch (error, stack) {
      _logger.severe("备份失败", error, stack);
    } finally {
      await _cleanup();
    }
  }
  
  @override
  Future<void> cancel() async {
    _logger.warning("任务被取消");
    await _cleanup();
  }
  
  Future<void> _initializeServices() async {
    // 初始化数据库连接
    // 加载配置
    // 配置文件下载器
    FileDownloader().configure(
      globalConfig: [
        (Config.holdingQueue, (6, 6, 3)),
        (Config.runInForegroundIfFileLargerThan, 256),
      ],
    );
  }
  
  Future<void> _performBackup() async {
    // 1. 同步本地资产
    // 2. 同步远程资产
    // 3. 构建上传列表
    // 4. 执行上传
  }
  
  Future<void> _cleanup() async {
    if (_isCleanedUp) return;
    
    _isCleanedUp = true;
    
    // 关闭数据库连接
    // 释放资源
    // 通知原生层清理完成
    await _backgroundHostApi.close();
  }
}

// 后台任务入口点
@pragma('vm:entry-point')
Future<void> backgroundSyncNativeEntrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  
  // 初始化数据库
  // 创建后台服务实例
  final service = BackgroundWorkerBgService();
  await service.init();
}
```

### 2. Provider 定义

创建 `lib/providers/background_worker.provider.dart`：

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/platform/background_worker_api.g.dart';
import 'package:immich_mobile/domain/services/background_worker.service.dart';

// 前台服务提供者
final backgroundWorkerFgServiceProvider = Provider<BackgroundWorkerFgService>((ref) {
  return BackgroundWorkerFgService(BackgroundWorkerFgHostApi());
});
```

---

## Android 侧实现

### 1. 添加依赖

在 `android/app/build.gradle` 中添加：

```gradle
dependencies {
    implementation "androidx.work:work-runtime-ktx:2.9.0"
}
```

### 2. BackgroundWorker 实现

创建 `android/app/src/main/kotlin/your/package/background/BackgroundWorker.kt`：

```kotlin
package your.package.background

import android.content.Context
import androidx.work.ListenableWorker
import androidx.work.WorkerParameters
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader

class BackgroundWorker(
    context: Context,
    params: WorkerParameters
) : ListenableWorker(context, params), BackgroundWorkerBgHostApi {
    
    private var engine: FlutterEngine? = null
    private var flutterApi: BackgroundWorkerFlutterApi? = null
    private val completionHandler = SettableFuture.create<Result>()
    private var isComplete = false
    
    companion object {
        const val ENGINE_CACHE_KEY = "background_worker_engine"
    }
    
    override fun startWork(): ListenableFuture<Result> {
        val loader = FlutterInjector.instance().flutterLoader()
        
        if (!loader.initialized()) {
            loader.startInitialization(applicationContext)
        }
        
        loader.ensureInitializationCompleteAsync(
            applicationContext,
            null,
            Handler(Looper.getMainLooper())
        ) {
            // 创建独立的 Flutter Engine
            engine = FlutterEngine(applicationContext)
            FlutterEngineCache.getInstance()
                .put(ENGINE_CACHE_KEY, engine!!)
            
            // 注册插件
            // MainActivity.registerPlugins(applicationContext, engine!!)
            
            // 设置 Pigeon API
            flutterApi = BackgroundWorkerFlutterApi(
                binaryMessenger = engine!!.dartExecutor.binaryMessenger
            )
            BackgroundWorkerBgHostApi.setUp(
                binaryMessenger = engine!!.dartExecutor.binaryMessenger,
                api = this
            )
            
            // 启动 Dart 入口点
            engine!!.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    loader.findAppBundlePath(),
                    "package:your_app/domain/services/background_worker.service.dart",
                    "backgroundSyncNativeEntrypoint"
                )
            )
        }
        
        return completionHandler
    }
    
    override fun onInitialized() {
        // Flutter 侧初始化完成，触发上传任务
        flutterApi?.onAndroidUpload { result ->
            result.fold(
                onSuccess = { completionHandler.set(Result.success()) },
                onFailure = { completionHandler.set(Result.failure()) }
            )
        }
    }
    
    override fun close() {
        if (isComplete) return
        
        flutterApi?.cancel {
            cleanup()
        }
        
        // 超时保护
        Handler(Looper.getMainLooper()).postDelayed({
            cleanup()
        }, 5000)
    }
    
    private fun cleanup() {
        if (isComplete) return
        isComplete = true
        
        engine?.destroy()
        engine = null
        flutterApi = null
        FlutterEngineCache.getInstance().remove(ENGINE_CACHE_KEY)
        
        if (!completionHandler.isDone) {
            completionHandler.set(Result.failure())
        }
    }
    
    override fun onStopped() {
        close()
    }
}
```

### 3. BackgroundWorkerApiImpl 实现

创建 `android/app/src/main/kotlin/your/package/background/BackgroundWorkerApiImpl.kt`：

```kotlin
package your.package.background

import android.content.Context
import android.provider.MediaStore
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class BackgroundWorkerApiImpl(private val context: Context) 
    : BackgroundWorkerFgHostApi {
    
    companion object {
        private const val BACKGROUND_WORKER_NAME = "background_worker"
        private const val OBSERVER_WORKER_NAME = "media_observer"
        
        fun enqueueBackgroundWorker(ctx: Context) {
            val constraints = Constraints.Builder()
                .setRequiresBatteryNotLow(true)
                .build()
            
            val work = OneTimeWorkRequest.Builder(BackgroundWorker::class.java)
                .setConstraints(constraints)
                .build()
            
            WorkManager.getInstance(ctx)
                .enqueueUniqueWork(
                    BACKGROUND_WORKER_NAME,
                    ExistingWorkPolicy.KEEP,
                    work
                )
        }
    }
    
    override fun enable() {
        // 启用媒体观察者
        enqueueMediaObserver(context)
    }
    
    override fun disable() {
        WorkManager.getInstance(context).apply {
            cancelUniqueWork(OBSERVER_WORKER_NAME)
            cancelUniqueWork(BACKGROUND_WORKER_NAME)
        }
    }
    
    override fun configure(settings: BackgroundWorkerSettings) {
        // 保存配置
        // 重新调度观察者
        enqueueMediaObserver(context)
    }
    
    override fun saveNotificationMessage(title: String, body: String) {
        // 保存通知配置
    }
    
    private fun enqueueMediaObserver(ctx: Context) {
        val constraints = Constraints.Builder().apply {
            addContentUriTrigger(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, true)
            addContentUriTrigger(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, true)
            setTriggerContentUpdateDelay(5, TimeUnit.SECONDS)
            setTriggerContentMaxDelay(50, TimeUnit.SECONDS)
        }.build()
        
        val work = OneTimeWorkRequest.Builder(MediaObserver::class.java)
            .setConstraints(constraints)
            .build()
        
        WorkManager.getInstance(ctx)
            .enqueueUniqueWork(
                OBSERVER_WORKER_NAME,
                ExistingWorkPolicy.REPLACE,
                work
            )
    }
}
```

### 4. 注册 API

在 `MainActivity.kt` 中：

```kotlin
import your.package.background.BackgroundWorkerApiImpl
import your.package.background.BackgroundWorkerFgHostApi

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 注册 Pigeon API
        BackgroundWorkerFgHostApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            BackgroundWorkerApiImpl(this)
        )
    }
}
```

### 5. AndroidManifest 配置

在 `AndroidManifest.xml` 中添加：

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

<application>
    <!-- 禁用默认 WorkManager 初始化 -->
    <provider
        android:name="androidx.startup.InitializationProvider"
        android:authorities="${applicationId}.androidx-startup"
        android:exported="false"
        tools:node="merge">
        <meta-data
            android:name="androidx.work.WorkManagerInitializer"
            android:value="androidx.startup"
            tools:node="remove" />
    </provider>
</application>
```

---

## iOS 侧实现

### 1. BackgroundWorker 实现

创建 `ios/Runner/Background/BackgroundWorker.swift`：

```swift
import Flutter
import BackgroundTasks

enum BackgroundTaskType {
    case refresh
    case processing
}

class BackgroundWorker: BackgroundWorkerBgHostApi {
    private let taskType: BackgroundTaskType
    private let maxSeconds: Int?
    private let completionHandler: (Bool) -> Void
    private let engine = FlutterEngine(name: "BackgroundWorker")
    private var flutterApi: BackgroundWorkerFlutterApi?
    private var isComplete = false
    
    init(
        taskType: BackgroundTaskType,
        maxSeconds: Int?,
        completionHandler: @escaping (Bool) -> Void
    ) {
        self.taskType = taskType
        self.maxSeconds = maxSeconds
        self.completionHandler = completionHandler
    }
    
    func run() {
        let isRunning = engine.run(
            withEntrypoint: "backgroundSyncNativeEntrypoint",
            libraryURI: "package:your_app/domain/services/background_worker.service.dart"
        )
        
        if !isRunning {
            complete(success: false)
            return
        }
        
        // 注册插件
        GeneratedPluginRegistrant.register(with: engine)
        // AppDelegate.registerPlugins(with: engine)
        
        flutterApi = BackgroundWorkerFlutterApi(
            binaryMessenger: engine.binaryMessenger
        )
        BackgroundWorkerBgHostApiSetup.setUp(
            binaryMessenger: engine.binaryMessenger,
            api: self
        )
        
        if let maxSeconds = maxSeconds {
            Timer.scheduledTimer(withTimeInterval: TimeInterval(maxSeconds), repeats: false) { _ in
                self.close()
            }
        }
    }
    
    func onInitialized() throws {
        flutterApi?.onIosUpload(
            isRefresh: taskType == .refresh,
            maxSeconds: maxSeconds.map { Int64($0) },
            completion: { result in
                switch result {
                case .success():
                    self.complete(success: true)
                case .failure(_):
                    self.close()
                }
            }
        )
    }
    
    func close() {
        if isComplete { return }
        
        flutterApi?.cancel { _ in
            self.complete(success: false)
        }
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            self.complete(success: false)
        }
    }
    
    private func complete(success: Bool) {
        if isComplete { return }
        isComplete = true
        
        // AppDelegate.cancelPlugins(with: engine)
        engine.destroyContext()
        flutterApi = nil
        completionHandler(success)
    }
}
```

### 2. BackgroundWorkerApiImpl 实现

创建 `ios/Runner/Background/BackgroundWorkerApiImpl.swift`：

```swift
import BackgroundTasks

class BackgroundWorkerApiImpl: BackgroundWorkerFgHostApi {
    private static let refreshTaskID = "your.app.background.refresh"
    private static let processingTaskID = "your.app.background.processing"
    private static let taskSemaphore = DispatchSemaphore(value: 1)
    
    static func registerBackgroundWorkers() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: processingTaskID,
            using: nil
        ) { task in
            if let processingTask = task as? BGProcessingTask {
                handleBackgroundProcessing(task: processingTask)
            }
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshTaskID,
            using: nil
        ) { task in
            if let refreshTask = task as? BGAppRefreshTask {
                handleBackgroundRefresh(task: refreshTask)
            }
        }
    }
    
    func enable() throws {
        BackgroundWorkerApiImpl.scheduleRefreshWorker()
        BackgroundWorkerApiImpl.scheduleProcessingWorker()
    }
    
    func disable() throws {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BackgroundWorkerApiImpl.refreshTaskID)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BackgroundWorkerApiImpl.processingTaskID)
    }
    
    func configure(settings: BackgroundWorkerSettings) throws {
        // 保存配置
    }
    
    func saveNotificationMessage(title: String, body: String) throws {
        // 保存通知配置
    }
    
    private static func scheduleRefreshWorker() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("无法调度刷新任务: \(error)")
        }
    }
    
    private static func scheduleProcessingWorker() {
        let request = BGProcessingTaskRequest(identifier: processingTaskID)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("无法调度处理任务: \(error)")
        }
    }
    
    private static func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleRefreshWorker()
        
        if taskSemaphore.wait(timeout: .now()) == .success {
            runBackgroundWorker(task: task, taskType: .refresh, maxSeconds: 20)
        } else {
            task.setTaskCompleted(success: false)
        }
    }
    
    private static func handleBackgroundProcessing(task: BGProcessingTask) {
        scheduleProcessingWorker()
        taskSemaphore.wait()
        runBackgroundWorker(task: task, taskType: .processing, maxSeconds: nil)
    }
    
    private static func runBackgroundWorker(
        task: BGTask,
        taskType: BackgroundTaskType,
        maxSeconds: Int?
    ) {
        defer { taskSemaphore.signal() }
        
        let semaphore = DispatchSemaphore(value: 0)
        var isSuccess = true
        
        let worker = BackgroundWorker(
            taskType: taskType,
            maxSeconds: maxSeconds
        ) { success in
            isSuccess = success
            semaphore.signal()
        }
        
        task.expirationHandler = {
            worker.close()
            isSuccess = false
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                semaphore.signal()
            }
        }
        
        DispatchQueue.main.async {
            worker.run()
        }
        
        semaphore.wait()
        task.setTaskCompleted(success: isSuccess)
    }
}
```

### 3. AppDelegate 配置

在 `AppDelegate.swift` 中：

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 注册后台任务
        BackgroundWorkerApiImpl.registerBackgroundWorkers()
        
        // 注册 Pigeon API
        if let controller = window?.rootViewController as? FlutterViewController {
            BackgroundWorkerFgHostApiSetup.setUp(
                binaryMessenger: controller.binaryMessenger,
                api: BackgroundWorkerApiImpl()
            )
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

### 4. Info.plist 配置

在 `Info.plist` 中添加：

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>your.app.background.refresh</string>
    <string>your.app.background.processing</string>
</array>
```

### 5. Capabilities 配置

在 Xcode 中启用：
- Background Modes
  - Background fetch
  - Background processing

---

## 集成步骤

### 1. 生成 Pigeon 代码

```bash
flutter pub get
flutter pub run pigeon --input pigeon/background_worker_api.dart
```

### 2. 在主应用中启用

```dart
// 在应用启动时
WidgetsBinding.instance.addPostFrameCallback((_) {
  ref.read(backgroundWorkerFgServiceProvider).enable();
  
  if (Platform.isAndroid) {
    ref.read(backgroundWorkerFgServiceProvider).saveNotificationMessage(
      "上传中",
      "正在备份您的照片"
    );
  }
});
```

### 3. 配置任务参数

```dart
await ref.read(backgroundWorkerFgServiceProvider).configure(
  minimumDelaySeconds: 5,
  requireCharging: false,
);
```

---

## 测试与调试

### Android 测试

1. **测试 WorkManager：**
```bash
adb shell am broadcast -a androidx.work.diagnostics.REQUEST_DIAGNOSTICS
```

2. **强制触发任务：**
```kotlin
WorkManager.getInstance(context)
    .enqueueUniqueWork(
        "background_worker",
        ExistingWorkPolicy.REPLACE,
        OneTimeWorkRequest.Builder(BackgroundWorker::class.java).build()
    )
```

### iOS 测试

在 Xcode 调试器中：

```objc
// 触发刷新任务
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"your.app.background.refresh"]

// 触发处理任务
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"your.app.background.processing"]
```

### 调试技巧

1. **日志记录：**
   - 使用 `Logger` 记录关键步骤
   - 在原生层和 Flutter 层都添加日志

2. **状态检查：**
   - 检查 Engine 是否创建
   - 检查任务是否调度
   - 检查约束条件是否满足

3. **性能监控：**
   - 监控内存使用
   - 监控任务执行时间
   - 监控网络使用

---

## 注意事项

1. **Engine 生命周期：**
   - 必须确保 Engine 在任务完成后销毁
   - 使用 Engine Cache 管理 Engine

2. **资源清理：**
   - 任务完成后立即清理所有资源
   - 使用 `_isCleanedUp` 标志防止重复清理

3. **错误处理：**
   - 所有操作都应该有错误处理
   - 记录错误日志便于调试

4. **平台差异：**
   - iOS 有严格的超时限制
   - Android 需要处理电池优化
   - 两个平台的约束条件不同

5. **测试：**
   - 在真实设备上测试
   - 测试不同场景（网络断开、低电量等）
   - 测试长时间运行的任务

---

*实现指南版本：1.0*

