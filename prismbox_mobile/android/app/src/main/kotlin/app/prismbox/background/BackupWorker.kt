package app.prismbox.background

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
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
    }

    /// Flutter Engine 实例
    private var engine: FlutterEngine? = null
    
    /// Flutter API（用于调用 Flutter 侧方法）
    private var flutterApi: BackgroundWorkerFlutterApi? = null
    
    /// 任务完成信号
    private var taskCompleted = CompletableDeferred<Result>()
    
    /// 是否已初始化
    private var isInitialized = false

    override suspend fun doWork(): Result {
        Log.i(TAG, "Starting background backup worker")

        return try {
            // 1. 初始化 Flutter Loader
            val loader = FlutterInjector.instance().flutterLoader()
            
            if (!loader.initialized()) {
                loader.startInitialization(applicationContext)
            }

            // 2. 等待 Flutter 初始化完成
            loader.ensureInitializationComplete(applicationContext, null)

            // 3. 创建独立的 Flutter Engine
            engine = FlutterEngine(applicationContext)
            
            // 4. 将 Engine 添加到缓存
            FlutterEngineCache.getInstance().put(ENGINE_CACHE_KEY, engine!!)

            // 5. 注册插件
            // 注册必要的插件到后台 Engine
            com.u163.glf9832.prismbox.MainActivity.registerPlugins(applicationContext, engine!!)

            // 6. 设置 Pigeon API
            flutterApi = BackgroundWorkerFlutterApi(
                binaryMessenger = engine!!.dartExecutor.binaryMessenger
            )
            BackgroundWorkerBgHostApi.setUp(
                binaryMessenger = engine!!.dartExecutor.binaryMessenger,
                api = this
            )

            // 7. 启动 Dart 入口点
            engine!!.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    loader.findAppBundlePath(),
                    ENTRY_POINT_LIBRARY,
                    ENTRY_POINT_FUNCTION
                )
            )

            // 8. 等待任务完成
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

            // 从缓存中移除 Engine
            FlutterEngineCache.getInstance().remove(ENGINE_CACHE_KEY)

            // 销毁 Engine
            engine?.destroy()
            engine = null

            // 清理 Flutter API
            flutterApi = null

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
        
        // TODO: 实现进度通知（如果需要前台服务）
        // 可以在这里更新通知栏显示进度
        // 注意：WorkManager 默认在后台运行，不需要前台服务
        // 如果需要前台服务，需要将 Worker 改为 ForegroundCoroutineWorker
    }
}

