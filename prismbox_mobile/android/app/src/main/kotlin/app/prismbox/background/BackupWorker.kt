package app.prismbox.background

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.ForegroundInfo
import androidx.work.ListenableWorker
import androidx.work.WorkerParameters
import androidx.concurrent.futures.ResolvableFuture
import com.google.common.util.concurrent.ListenableFuture
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import io.flutter.plugin.common.MethodChannel

/**
 * 后台备份 Worker
 * 
 * 使用 WorkManager 在后台执行备份任务
 * 创建独立的 Flutter Engine 以隔离后台任务
 * 
 * **职责**：
 * - 创建独立 Flutter Engine
 * - 注册 Pigeon API
 * - 启动后台任务入口点
 * - 管理 Engine 生命周期
 * - 处理系统强制停止
 */
class BackupWorker(
    context: Context,
    params: WorkerParameters
) : ListenableWorker(context, params), BackgroundWorkerBgHostApi, MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "BackupWorker"
        
        /// Engine 缓存键
        const val ENGINE_CACHE_KEY = "prismbox_background_worker_engine"
        
        /// Flutter 入口点函数名
        const val ENTRY_POINT_FUNCTION = "backgroundSyncNativeEntrypoint"
        
        /// Flutter 入口点库路径
        const val ENTRY_POINT_LIBRARY = "package:prismbox/features/background_backup/service/background_worker_bg_service.dart"
        
        /// 通知相关常量
        private const val NOTIFICATION_CHANNEL_ID = "prismbox_backup_channel"
        private const val NOTIFICATION_CHANNEL_NAME = "后台备份"
        private const val NOTIFICATION_ID = 1001
    }

    /// Flutter Engine 实例
    private var engine: FlutterEngine? = null
    
    /// Flutter API（用于调用 Flutter 侧方法）
    private var flutterApi: BackgroundWorkerFlutterApi? = null
    
    /// 后台通信通道
    private var backgroundChannel: MethodChannel? = null
    
    /// 任务完成 Future
    private val resolvableFuture = ResolvableFuture.create<Result>()
    
    /// 是否已初始化
    private var isInitialized = false
    
    /// 备份开始时间
    private var timeBackupStarted: Long = 0L
    
    /// 前台服务 Future（用于等待前台服务设置完成）
    private var fgFuture: ListenableFuture<Void>? = null
    
    /// 通知管理器
    private val notificationManager = 
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    
    /// 是否忽略电池优化
    private val isIgnoringBatteryOptimizations = isIgnoringBatteryOptimizations(context)
    
    /// 通知构建器（复用以提高性能）
    private var notificationBuilder: NotificationCompat.Builder? = null

    override fun startWork(): ListenableFuture<Result> {
        Log.i(TAG, "Starting background backup worker")

        try {
            // 1. 创建通知渠道
            createNotificationChannel()
            
            // 2. 立即显示初始通知（无论是否忽略电池优化）
            val initialNotification = createNotification(
                title = "后台备份",
                content = "正在准备备份...",
                progress = 0,
                max = 100,
                indeterminate = true
            )
            
            // 如果忽略电池优化，将 Worker 提升为前台服务
            if (isIgnoringBatteryOptimizations) {
                fgFuture = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    setForegroundAsync(
                        ForegroundInfo(
                            NOTIFICATION_ID,
                            initialNotification,
                            FOREGROUND_SERVICE_TYPE_DATA_SYNC
                        )
                    )
                } else {
                    setForegroundAsync(
                        ForegroundInfo(
                            NOTIFICATION_ID,
                            initialNotification
                        )
                    )
                }
                Log.i(TAG, "Backup worker promoted to foreground service")
            } else {
                // 即使没有忽略电池优化，也显示通知（普通通知）
                notificationManager.notify(NOTIFICATION_ID, initialNotification)
                Log.i(TAG, "Backup worker notification shown (not foreground service)")
            }

            // 3. 初始化 Flutter Loader
            val loader = FlutterInjector.instance().flutterLoader()
            
            if (!loader.initialized()) {
                loader.startInitialization(applicationContext)
            }

            // 4. 等待 Flutter 初始化完成（异步）
            loader.ensureInitializationCompleteAsync(
                applicationContext,
                null,
                Handler(Looper.getMainLooper())
            ) {
                runDart()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Background backup worker failed", e)
            if (!resolvableFuture.isDone) {
                resolvableFuture.set(Result.failure())
            }
        }

        return resolvableFuture
    }
    
    /**
     * 启动 Dart 运行时/引擎并调用入口点函数
     */
    private fun runDart() {
        val loader = FlutterInjector.instance().flutterLoader()
        
        // 创建独立的 Flutter Engine
        engine = FlutterEngine(applicationContext)
        
        // 将 Engine 添加到缓存
        FlutterEngineCache.getInstance().put(ENGINE_CACHE_KEY, engine!!)

        // 注册插件
        com.u163.glf9832.prismbox.MainActivity.registerPlugins(applicationContext, engine!!)

        // 设置后台通信通道
        backgroundChannel = MethodChannel(engine!!.dartExecutor, "prismbox/backgroundChannel")
        backgroundChannel?.setMethodCallHandler(this)

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
                ENTRY_POINT_LIBRARY,
                ENTRY_POINT_FUNCTION
            )
        )
    }
    
    /**
     * 处理系统强制停止
     */
    override fun onStopped() {
        Log.d(TAG, "onStopped - system is stopping the worker")
        // 当系统需要停止此 worker 时调用（约束不再满足或系统需要资源）
        Handler(Looper.getMainLooper()).postAtFrontOfQueue {
            backgroundChannel?.invokeMethod("systemStop", null)
        }
        waitOnSetForegroundAsync()
        // 不能 await/get(block) resolvableFuture，因为它已经被取消（会抛出 CancellationException）
        // 相反，等待 5 秒后强制停止备份工作
        Handler(Looper.getMainLooper()).postDelayed({
            stopEngine(null)
        }, 5000)
    }
    
    /**
     * 等待前台服务设置完成
     */
    private fun waitOnSetForegroundAsync() {
        val fg = this.fgFuture
        if (fg != null && !fg.isCancelled && !fg.isDone) {
            try {
                fg.get(500, java.util.concurrent.TimeUnit.MILLISECONDS)
            } catch (e: Exception) {
                // 忽略，没有需要做的
            }
        }
    }
    
    /**
     * 停止引擎并设置结果
     */
    private fun stopEngine(result: Result?) {
        clearBackgroundNotification()
        engine?.destroy()
        engine = null
        backgroundChannel = null
        if (result != null) {
            Log.d(TAG, "stopEngine result=${result}")
            if (!resolvableFuture.isDone) {
                resolvableFuture.set(result)
            }
        }
        waitOnSetForegroundAsync()
    }
    
    /**
     * 清除后台通知
     */
    private fun clearBackgroundNotification() {
        notificationManager.cancel(NOTIFICATION_ID)
    }
    
    /**
     * 处理后台通道的方法调用
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "systemStop" -> {
                Log.d(TAG, "Received systemStop from Flutter")
                // 通知 Flutter 侧取消任务
                flutterApi?.cancel { _ ->
                    // 忽略结果
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }


    /**
     * BackgroundWorkerBgHostApi 接口实现
     */
    
    override fun onInitialized() {
        if (isInitialized) {
            Log.w(TAG, "Background worker already initialized")
            return
        }
        
        isInitialized = true
        timeBackupStarted = SystemClock.uptimeMillis()
        Log.i(TAG, "Background worker initialized, starting upload")
        
        // 调用 Flutter 侧的上传方法
        flutterApi?.onAndroidUpload { result ->
            result.fold(
                onSuccess = {
                    Log.i(TAG, "Android upload completed successfully")
                    if (!resolvableFuture.isDone) {
                        resolvableFuture.set(Result.success())
                    }
                },
                onFailure = { exception ->
                    Log.e(TAG, "Android upload failed", exception)
                    if (!resolvableFuture.isDone) {
                        resolvableFuture.set(Result.failure())
                    }
                }
            )
        }
    }

    override fun onCompleted() {
        Log.i(TAG, "Background worker task completed")
        if (!resolvableFuture.isDone) {
            resolvableFuture.set(Result.success())
        }
    }
    
    override fun hasContentChanged(): Boolean {
        val prefs = applicationContext.getSharedPreferences(
            BackgroundWorkerPreferences.SHARED_PREF_NAME,
            Context.MODE_PRIVATE
        )
        val lastChange = prefs.getLong(
            BackgroundWorkerPreferences.SHARED_PREF_LAST_CHANGE,
            timeBackupStarted
        )
        val hasContentChanged = lastChange > timeBackupStarted
        timeBackupStarted = SystemClock.uptimeMillis()
        return hasContentChanged
    }

    override fun updateProgress(
        uploadedCount: Long,
        totalCount: Long,
        currentFileName: String?
    ) {
        Log.d(TAG, "Upload progress: $uploadedCount/$totalCount - $currentFileName")
        
        // 更新通知栏显示进度
        updateNotification(
            uploadedCount = uploadedCount.toInt(),
            totalCount = totalCount.toInt(),
            currentFileName = currentFileName
        )
    }
    
    /// 创建通知渠道
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT  // 提升重要性，确保通知可见
            ).apply {
                description = "后台备份进度通知"
                setShowBadge(false)
                enableVibration(false)  // 不震动
                enableLights(false)    // 不闪烁
            }
            notificationManager.createNotificationChannel(channel)
            Log.i(TAG, "Notification channel created with IMPORTANCE_DEFAULT")
        }
    }
    
    /// 创建通知
    private fun createNotification(
        title: String,
        content: String,
        progress: Int = 0,
        max: Int = 100,
        indeterminate: Boolean = false
    ): Notification {
        // 复用构建器以提高性能
        if (notificationBuilder == null) {
            // 使用应用图标作为通知图标（从 mipmap 资源中获取）
            val iconResId = applicationContext.resources.getIdentifier(
                "ic_launcher",
                "mipmap",
                applicationContext.packageName
            )
            val smallIcon = if (iconResId != 0) iconResId else android.R.drawable.ic_menu_upload
            
            notificationBuilder = NotificationCompat.Builder(applicationContext, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(smallIcon)
                .setOnlyAlertOnce(true)
                .setOngoing(true) // 常驻通知
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)  // 提升优先级
                .setCategory(NotificationCompat.CATEGORY_PROGRESS)
                .setAutoCancel(false)  // 不自动取消
        }
        
        val builder = notificationBuilder!!
            .setContentTitle(title)
            .setContentText(content)
            .setProgress(max, progress, indeterminate)
        
        return builder.build()
    }
    
    /// 更新通知
    private fun updateNotification(
        uploadedCount: Int,
        totalCount: Int,
        currentFileName: String?
    ) {
        val title = "后台备份"
        // 显示任务进度：已完成/总任务数
        val content = if (currentFileName != null && currentFileName.isNotEmpty()) {
            "正在上传: $currentFileName\n已完成 $uploadedCount/$totalCount 个任务"
        } else {
            "已完成 $uploadedCount/$totalCount 个任务"
        }
        
        val notification = createNotification(
            title = title,
            content = content,
            progress = uploadedCount,
            max = totalCount,
            indeterminate = false
        )
        
        // 如果已提升为前台服务，使用 setForegroundAsync 更新
        if (isIgnoringBatteryOptimizations) {
            setForegroundAsync(
                ForegroundInfo(
                    NOTIFICATION_ID,
                    notification,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        FOREGROUND_SERVICE_TYPE_DATA_SYNC
                    } else {
                        0
                    }
                )
            )
        } else {
            // 即使没有提升为前台服务，也更新通知
            notificationManager.notify(NOTIFICATION_ID, notification)
        }
        
        Log.d(TAG, "Notification updated: $uploadedCount/$totalCount")
    }
    
    /// 检查是否忽略电池优化
    private fun isIgnoringBatteryOptimizations(ctx: Context): Boolean {
        val powerManager = ctx.getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(ctx.packageName)
    }
}

