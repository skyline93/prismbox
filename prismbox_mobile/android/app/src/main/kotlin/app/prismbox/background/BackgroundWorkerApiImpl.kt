package app.prismbox.background

import android.content.Context
import android.os.SystemClock
import android.provider.MediaStore
import android.util.Log
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.PeriodicWorkRequest
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

private const val TAG = "BackgroundWorkerApiImpl"

/// 前台 API 实现
/// 实现 BackgroundWorkerFgHostApi 接口，处理 Flutter 侧的 API 调用
class BackgroundWorkerApiImpl(private val context: Context) : BackgroundWorkerFgHostApi {
    private val ctx: Context = context.applicationContext

    override fun enable(callbackHandle: Long, notificationTitle: String, immediate: Boolean) {
        Log.i(TAG, "Enabling background worker (callbackHandle=$callbackHandle, immediate=$immediate)")
        
        // 标记服务为启用状态
        BackgroundWorkerPreferences(ctx).setServiceEnabled(true)
        
        // 保存通知配置
        BackgroundWorkerPreferences(ctx).updateNotificationConfig(notificationTitle, "")
        
        // 启用媒体观察器 Worker（监听媒体库变化）
        enqueueMediaObserver(ctx)
        
        // 如果需要立即执行，可以手动触发一次备份任务
        if (immediate) {
            enqueueBackgroundWorker(ctx)
        }
    }

    override fun saveNotificationMessage(title: String, body: String) {
        Log.d(TAG, "Saving notification message: $title - $body")
        BackgroundWorkerPreferences(ctx).updateNotificationConfig(title, body)
    }

    override fun configure(settings: BackgroundWorkerSettings) {
        Log.i(TAG, "Configuring background worker: $settings")
        
        // 保存配置
        BackgroundWorkerPreferences(ctx).updateSettings(settings)
        
        // 重新调度 Worker 以应用新配置
        enqueueMediaObserver(ctx)
    }

    override fun disable() {
        Log.i(TAG, "Disabling background worker")
        
        // 标记服务为禁用状态
        BackgroundWorkerPreferences(ctx).setServiceEnabled(false)
        
        // 取消所有后台任务
        WorkManager.getInstance(ctx).apply {
            cancelUniqueWork(OBSERVER_WORKER_NAME)
            cancelUniqueWork(BACKGROUND_WORKER_NAME)
        }
        
        Log.i(TAG, "Cancelled background upload tasks")
    }

    companion object {
        private const val BACKGROUND_WORKER_NAME = "prismbox/BackgroundWorkerV1"
        private const val OBSERVER_WORKER_NAME = "prismbox/MediaObserverV1"
        private const val PERIODIC_WORKER_NAME = "prismbox/PeriodicWorkerV1"
        const val ENGINE_CACHE_KEY = "prismbox_background_worker_engine"

        /// 启用媒体观察器 Worker
        /// 监听媒体库变化，当有新照片/视频时触发备份任务
        fun enqueueMediaObserver(ctx: Context) {
            val settings = BackgroundWorkerPreferences(ctx).getSettings()
            
            val constraints = Constraints.Builder().apply {
                // 监听图片和视频的变化
                addContentUriTrigger(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, true)
                addContentUriTrigger(MediaStore.Images.Media.INTERNAL_CONTENT_URI, true)
                addContentUriTrigger(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, true)
                addContentUriTrigger(MediaStore.Video.Media.INTERNAL_CONTENT_URI, true)
                
                // 设置触发延迟
                setTriggerContentUpdateDelay(
                    settings.minimumDelaySeconds,
                    TimeUnit.SECONDS
                )
                setTriggerContentMaxDelay(
                    settings.minimumDelaySeconds * 10,
                    TimeUnit.SECONDS
                )
                
                // 应用配置约束
                setRequiresCharging(settings.requiresCharging)
                setRequiresBatteryNotLow(settings.requiresBatteryNotLow)
                
                // 网络类型约束
                if (settings.requiresNetworkType) {
                    setRequiredNetworkType(androidx.work.NetworkType.UNMETERED) // WiFi
                } else {
                    setRequiredNetworkType(androidx.work.NetworkType.CONNECTED)
                }
            }.build()

            val work = OneTimeWorkRequest.Builder(MediaObserverWorker::class.java)
                .setConstraints(constraints)
                .build()
                
            WorkManager.getInstance(ctx)
                .enqueueUniqueWork(
                    OBSERVER_WORKER_NAME,
                    ExistingWorkPolicy.REPLACE,
                    work
                )

            Log.i(
                TAG,
                "Enqueued media observer worker with name: $OBSERVER_WORKER_NAME and settings: $settings"
            )
        }

        /// 启用后台备份 Worker
        /// 执行实际的备份任务
        fun enqueueBackgroundWorker(ctx: Context) {
            val settings = BackgroundWorkerPreferences(ctx).getSettings()
            
            val constraints = Constraints.Builder().apply {
                // 应用配置约束
                setRequiresCharging(settings.requiresCharging)
                setRequiresBatteryNotLow(settings.requiresBatteryNotLow)
                
                // 网络类型约束
                if (settings.requiresNetworkType) {
                    setRequiredNetworkType(androidx.work.NetworkType.UNMETERED) // WiFi
                } else {
                    setRequiredNetworkType(androidx.work.NetworkType.CONNECTED)
                }
            }.build()

            val work = OneTimeWorkRequest.Builder(BackupWorker::class.java)
                .setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 1, TimeUnit.MINUTES)
                .build()
                
            WorkManager.getInstance(ctx)
                .enqueueUniqueWork(
                    BACKGROUND_WORKER_NAME,
                    ExistingWorkPolicy.KEEP,
                    work
                )

            Log.i(TAG, "Enqueued background worker with name: $BACKGROUND_WORKER_NAME and settings: $settings")
        }

        /// 检查后台 Worker 是否正在运行
        fun isBackgroundWorkerRunning(): Boolean {
            // 通过检查 Engine 缓存来判断 Worker 是否正在运行
            return io.flutter.embedding.engine.FlutterEngineCache
                .getInstance()
                .get(ENGINE_CACHE_KEY) != null
        }

        /// 取消后台 Worker
        fun cancelBackgroundWorker(ctx: Context) {
            WorkManager.getInstance(ctx).cancelUniqueWork(BACKGROUND_WORKER_NAME)
            io.flutter.embedding.engine.FlutterEngineCache
                .getInstance()
                .remove(ENGINE_CACHE_KEY)

            Log.i(TAG, "Cancelled background upload task")
        }
        
        /// 启用定期备份 Worker
        /// 每 15 分钟触发一次备份检查
        fun enqueuePeriodicWorker(ctx: Context) {
            val settings = BackgroundWorkerPreferences(ctx).getSettings()
            
            val constraints = Constraints.Builder().apply {
                setRequiresCharging(settings.requiresCharging)
                setRequiresBatteryNotLow(settings.requiresBatteryNotLow)
                
                if (settings.requiresNetworkType) {
                    setRequiredNetworkType(androidx.work.NetworkType.UNMETERED) // WiFi
                } else {
                    setRequiredNetworkType(androidx.work.NetworkType.CONNECTED)
                }
            }.build()
            
            // 使用 PeriodicWorkRequest，最小间隔 15 分钟
            val periodicWork = PeriodicWorkRequest.Builder(
                BackupWorker::class.java,
                15, // 间隔时间（分钟）
                TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .setBackoffCriteria(
                    BackoffPolicy.EXPONENTIAL,
                    1,
                    TimeUnit.MINUTES
                )
                .build()
            
            WorkManager.getInstance(ctx)
                .enqueueUniquePeriodicWork(
                    PERIODIC_WORKER_NAME,
                    ExistingPeriodicWorkPolicy.UPDATE, // 更新现有任务
                    periodicWork
                )
            
            Log.i(TAG, "Enqueued periodic backup worker with interval: 15 minutes")
        }
        
    }
}

/// 后台 Worker 配置和通知设置的存储类
class BackgroundWorkerPreferences(private val context: Context) {
    companion object {
        const val SHARED_PREF_NAME = "prismboxBackgroundService"
        const val SHARED_PREF_LAST_CHANGE = "lastChange"
    }
    
    private val prefs = context.getSharedPreferences(
        SHARED_PREF_NAME,
        Context.MODE_PRIVATE
    )
    
    private val SERVICE_ENABLED_KEY = "service_enabled"
    private val LAST_BACKUP_TRIGGER_TIME_KEY = "last_backup_trigger_time"

    fun getSettings(): BackgroundWorkerSettings {
        return BackgroundWorkerSettings(
            requiresCharging = prefs.getBoolean("requires_charging", false),
            requiresBatteryNotLow = prefs.getBoolean("requires_battery_not_low", true),
            minimumDelaySeconds = prefs.getLong("minimum_delay_seconds", 300),
            requiresNetworkType = prefs.getBoolean("requires_network_type", true)
        )
    }

    fun updateSettings(settings: BackgroundWorkerSettings) {
        prefs.edit()
            .putBoolean("requires_charging", settings.requiresCharging)
            .putBoolean("requires_battery_not_low", settings.requiresBatteryNotLow)
            .putLong("minimum_delay_seconds", settings.minimumDelaySeconds.toLong())
            .putBoolean("requires_network_type", settings.requiresNetworkType)
            .apply()
    }

    fun getNotificationConfig(): Pair<String, String> {
        return Pair(
            prefs.getString("notification_title", "后台备份") ?: "后台备份",
            prefs.getString("notification_body", "正在备份您的照片和视频...") ?: "正在备份您的照片和视频..."
        )
    }

    fun updateNotificationConfig(title: String, body: String) {
        prefs.edit()
            .putString("notification_title", title)
            .putString("notification_body", body)
            .apply()
    }
    
    /// 检查服务是否启用
    fun getServiceEnabled(): Boolean {
        return prefs.getBoolean(SERVICE_ENABLED_KEY, false)
    }
    
    /// 设置服务启用状态
    fun setServiceEnabled(enabled: Boolean) {
        prefs.edit()
            .putBoolean(SERVICE_ENABLED_KEY, enabled)
            .apply()
    }
    
    /// 获取最后备份触发时间
    fun getLastBackupTriggerTime(): Long? {
        val time = prefs.getLong(LAST_BACKUP_TRIGGER_TIME_KEY, 0)
        return if (time > 0) time else null
    }
    
    /// 设置最后备份触发时间
    fun setLastBackupTriggerTime(time: Long) {
        prefs.edit()
            .putLong(LAST_BACKUP_TRIGGER_TIME_KEY, time)
            .apply()
    }
}

/// 媒体观察器 Worker
/// 
/// 监听媒体库（MediaStore）的变化，当有新照片或视频时触发备份任务
/// 
/// **工作原理**：
/// 1. 使用 WorkManager 的 ContentUriTrigger 监听 MediaStore 的变化
/// 2. 当检测到媒体库变化时，WorkManager 会触发此 Worker
/// 3. Worker 检查是否有实际的内容变化（triggeredContentUris）
/// 4. 如果有变化，触发 BackupWorker 执行备份
/// 5. 无论是否有变化，都会重新注册自己以继续监听
class MediaObserverWorker(
    context: Context,
    params: androidx.work.WorkerParameters
) : androidx.work.Worker(context, params) {
    
    companion object {
        private const val TAG = "MediaObserverWorker"
    }

    override fun doWork(): androidx.work.ListenableWorker.Result {
        Log.i(TAG, "MediaObserverWorker triggered")
        
        // 1. 检查服务是否启用
        if (!isServiceEnabled()) {
            Log.d(TAG, "Background service is disabled, skipping media observer")
            return androidx.work.ListenableWorker.Result.failure()
        }
        
        // 2. 检查是否有实际的内容变化
        // WorkManager 会在检测到 MediaStore 变化时触发此 Worker
        // triggeredContentUris 包含触发此 Worker 的内容 URI 列表
        val hasContentChanges = triggeredContentUris.isNotEmpty()
        
        if (hasContentChanges) {
            Log.i(
                TAG,
                "Media library changed, detected ${triggeredContentUris.size} content URIs. Triggering backup."
            )
            
            // 记录变化的 URI（用于调试）
            triggeredContentUris.forEach { uri ->
                Log.d(TAG, "Changed content URI: $uri")
            }
            
            // 3. 节流检查（避免频繁触发）
            val prefs = BackgroundWorkerPreferences(applicationContext)
            val lastTriggerTime = prefs.getLastBackupTriggerTime()
            
            if (lastTriggerTime != null) {
                val timeSinceLastTrigger = System.currentTimeMillis() - lastTriggerTime
                val minIntervalMs = 30 * 1000 // 30 秒
                
                if (timeSinceLastTrigger < minIntervalMs) {
                    Log.d(
                        TAG,
                        "MediaObserver triggered too soon (${timeSinceLastTrigger}ms ago), "
                        + "throttling backup trigger"
                    )
                    // 重新注册自己以继续监听
                    BackgroundWorkerApiImpl.enqueueMediaObserver(applicationContext)
                    return androidx.work.ListenableWorker.Result.success()
                }
            }
            
            // 更新最后变化时间（用于内容变化检查）
            val sharedPrefs = applicationContext.getSharedPreferences(
                BackgroundWorkerPreferences.SHARED_PREF_NAME,
                Context.MODE_PRIVATE
            )
            sharedPrefs.edit().putLong(
                BackgroundWorkerPreferences.SHARED_PREF_LAST_CHANGE,
                SystemClock.uptimeMillis()
            ).apply()
            
            // 4. 触发后台备份 Worker（无延迟，立即执行）
            BackgroundWorkerApiImpl.enqueueBackgroundWorker(applicationContext)
        } else {
            Log.d(TAG, "MediaObserverWorker triggered but no content changes detected")
        }
        
        // 4. 重新注册自己以继续监听媒体库变化
        // 使用 REPLACE 策略确保只有一个 Observer Worker 在运行
        BackgroundWorkerApiImpl.enqueueMediaObserver(applicationContext)
        
        Log.i(TAG, "MediaObserverWorker completed successfully")
        return androidx.work.ListenableWorker.Result.success()
    }
    
    /// 检查后台服务是否启用
    private fun isServiceEnabled(): Boolean {
        return BackgroundWorkerPreferences(applicationContext)
            .getServiceEnabled()
    }
}

