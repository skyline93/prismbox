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
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import android.os.Handler
import android.os.Looper
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.withTimeoutOrNull

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
 */
class BackupWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params), BackgroundWorkerBgHostApi {

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
    
    /// 任务完成信号
    private var taskCompleted = CompletableDeferred<Result>()
    
    /// 是否已初始化
    private var isInitialized = false
    
    /// 通知管理器
    private val notificationManager = 
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    
    /// 是否忽略电池优化
    private val isIgnoringBatteryOptimizations = isIgnoringBatteryOptimizations(context)
    
    /// 通知构建器（复用以提高性能）
    private var notificationBuilder: NotificationCompat.Builder? = null

    override suspend fun doWork(): Result {
        Log.i(TAG, "Starting background backup worker")

        return try {
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
                setForeground(
                    ForegroundInfo(
                        NOTIFICATION_ID,
                        initialNotification,
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            FOREGROUND_SERVICE_TYPE_DATA_SYNC
                        } else {
                            0
                        }
                    )
                )
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

            // 4. 等待 Flutter 初始化完成
            loader.ensureInitializationComplete(applicationContext, null)

            // 5. 创建独立的 Flutter Engine
            engine = FlutterEngine(applicationContext)
            
            // 6. 将 Engine 添加到缓存
            FlutterEngineCache.getInstance().put(ENGINE_CACHE_KEY, engine!!)

            // 7. 注册插件
            // 注册必要的插件到后台 Engine
            com.u163.glf9832.prismbox.MainActivity.registerPlugins(applicationContext, engine!!)

            // 8. 设置 Pigeon API
            flutterApi = BackgroundWorkerFlutterApi(
                binaryMessenger = engine!!.dartExecutor.binaryMessenger
            )
            BackgroundWorkerBgHostApi.setUp(
                binaryMessenger = engine!!.dartExecutor.binaryMessenger,
                api = this
            )

            // 9. 启动 Dart 入口点
            engine!!.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    loader.findAppBundlePath(),
                    ENTRY_POINT_LIBRARY,
                    ENTRY_POINT_FUNCTION
                )
            )

            // 10. 等待任务完成
            // 注意：实际的任务执行在 Flutter 侧，通过 onInitialized() 触发
            // 任务完成后通过 onCompleted() 通知，这里等待任务完成信号
            return taskCompleted.await()
            
        } catch (e: Exception) {
            Log.e(TAG, "Background backup worker failed", e)
            if (!taskCompleted.isCompleted) {
                taskCompleted.complete(Result.failure())
            }
            return taskCompleted.await()
        } finally {
            // 清理资源
            cleanup()
        }
    }

    /// 清理资源
    private fun cleanup() {
        try {
            Log.i(TAG, "Cleaning up background worker resources")

            // 取消通知
            notificationManager.cancel(NOTIFICATION_ID)

            // 从缓存中移除 Engine
            FlutterEngineCache.getInstance().remove(ENGINE_CACHE_KEY)

            // 销毁 Engine
            engine?.destroy()
            engine = null

            // 清理 Flutter API
            flutterApi = null

            // 清理通知构建器
            notificationBuilder = null

            Log.i(TAG, "Background worker resources cleaned up")
        } catch (e: Exception) {
            Log.e(TAG, "Error during cleanup", e)
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
        Log.i(TAG, "Background worker initialized, starting upload")
        
        // 调用 Flutter 侧的上传方法
        flutterApi?.onAndroidUpload { result ->
            result.fold(
                onSuccess = {
                    Log.i(TAG, "Android upload completed successfully")
                    if (!taskCompleted.isCompleted) {
                        taskCompleted.complete(Result.success())
                    }
                },
                onFailure = { exception ->
                    Log.e(TAG, "Android upload failed", exception)
                    if (!taskCompleted.isCompleted) {
                        taskCompleted.complete(Result.failure())
                    }
                }
            )
        }
    }

    override fun onCompleted() {
        Log.i(TAG, "Background worker task completed")
        if (!taskCompleted.isCompleted) {
            taskCompleted.complete(Result.success())
        }
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

