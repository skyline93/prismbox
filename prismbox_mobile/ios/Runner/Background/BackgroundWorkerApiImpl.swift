import BackgroundTasks
import Flutter

class BackgroundWorkerApiImpl: BackgroundWorkerFgHostApi {
    
    func enable(callbackHandle: Int64, notificationTitle: String, immediate: Bool) throws {
        BackgroundWorkerApiImpl.scheduleRefreshWorker()
        BackgroundWorkerApiImpl.scheduleProcessingWorker()
        print("BackgroundWorkerApiImpl:enable Background worker scheduled (iOS ignores callbackHandle)")
    }
    
    func configure(settings: BackgroundWorkerSettings) throws {
        // Android only - iOS uses BGTaskScheduler settings
    }
    
    func saveNotificationMessage(title: String, body: String) throws {
        // Android only - iOS notifications are handled by Flutter
    }
    
    func disable() throws {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BackgroundWorkerApiImpl.refreshTaskID)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BackgroundWorkerApiImpl.processingTaskID)
        print("BackgroundWorkerApiImpl:disable Disabled background workers")
    }
    
    private static let refreshTaskID = "com.u163.glf9832.prismbox.background.refreshUpload"
    private static let processingTaskID = "com.u163.glf9832.prismbox.background.processingUpload"
    private static let taskSemaphore = DispatchSemaphore(value: 1)
    
    /// 注册后台任务处理器
    /// 必须在 AppDelegate 的 application(_:didFinishLaunchingWithOptions:) 中调用
    public static func registerBackgroundWorkers() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: processingTaskID,
            using: nil
        ) { task in
            if task is BGProcessingTask {
                handleBackgroundProcessing(task: task as! BGProcessingTask)
            }
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshTaskID,
            using: nil
        ) { task in
            if task is BGAppRefreshTask {
                handleBackgroundRefresh(task: task as! BGAppRefreshTask)
            }
        }
        
        print("BackgroundWorkerApiImpl: Registered background workers")
    }
    
    /// 调度刷新任务（BGAppRefreshTask - 短时间运行）
    private static func scheduleRefreshWorker() {
        let backgroundRefresh = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        backgroundRefresh.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60) // 5 分钟后
        
        do {
            try BGTaskScheduler.shared.submit(backgroundRefresh)
            print("BackgroundWorkerApiImpl: Scheduled refresh worker")
        } catch {
            print("BackgroundWorkerApiImpl: Could not schedule the refresh upload task: \(error.localizedDescription)")
        }
    }
    
    /// 调度处理任务（BGProcessingTask - 长时间运行）
    private static func scheduleProcessingWorker() {
        let backgroundProcessing = BGProcessingTaskRequest(identifier: processingTaskID)
        backgroundProcessing.requiresNetworkConnectivity = true
        backgroundProcessing.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 分钟后
        
        do {
            try BGTaskScheduler.shared.submit(backgroundProcessing)
            print("BackgroundWorkerApiImpl: Scheduled processing worker")
        } catch {
            print("BackgroundWorkerApiImpl: Could not schedule the processing upload task: \(error.localizedDescription)")
        }
    }
    
    /// 处理刷新任务（短时间运行，约 30 秒）
    private static func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // 重新调度下一次刷新任务
        scheduleRefreshWorker()
        
        // 使用信号量防止并发执行（带超时，避免无限等待）
        if taskSemaphore.wait(timeout: .now()) == .success {
            // 刷新任务限制在 20 秒内完成
            runBackgroundWorker(task: task, taskType: .refresh, maxSeconds: 20)
        } else {
            // 如果另一个任务正在运行，放弃本次执行
            print("BackgroundWorkerApiImpl: Another task is running, skipping refresh task")
            task.setTaskCompleted(success: false)
        }
    }
    
    /// 处理处理任务（长时间运行，系统决定何时终止）
    private static func handleBackgroundProcessing(task: BGProcessingTask) {
        // 重新调度下一次处理任务
        scheduleProcessingWorker()
        
        // 使用信号量防止并发执行（带超时，避免无限等待）
        // 如果另一个任务正在运行，等待最多 5 秒
        if taskSemaphore.wait(timeout: .now() + 5) == .success {
            // 处理任务没有时间限制，但系统可能随时发出过期信号
            runBackgroundWorker(task: task, taskType: .processing, maxSeconds: nil)
        } else {
            // 如果等待超时，放弃本次执行
            print("BackgroundWorkerApiImpl: Timeout waiting for semaphore, skipping processing task")
            task.setTaskCompleted(success: false)
        }
    }
    
    /// 执行后台工作器
    /// 
    /// - Parameters:
    ///   - task: iOS 后台任务，提供执行上下文
    ///   - taskType: 后台操作类型（refresh 或 processing）
    ///   - maxSeconds: 可选的超时时间（秒）
    private static func runBackgroundWorker(
        task: BGTask,
        taskType: BackgroundTaskType,
        maxSeconds: Int?
    ) {
        defer { taskSemaphore.signal() }
        let semaphore = DispatchSemaphore(value: 0)
        var isSuccess = true
        var currentTaskId: String? = nil
        
        // 创建后台工作器
        let worker = BackgroundWorker(
            taskType: taskType,
            maxSeconds: maxSeconds
        ) { success in
            isSuccess = success
            semaphore.signal()
        }
        
        // 设置任务过期处理
        task.expirationHandler = {
            print("BackgroundWorkerApiImpl: Task expired, cancelling...")
            
            // 快速保存状态（不做耗时操作）
            // 保存当前任务 ID 和进度（如果可用）
            if let taskId = currentTaskId {
                UserDefaults.standard.set(taskId, forKey: "background_task_last_id")
                UserDefaults.standard.set(Date(), forKey: "background_task_last_expired")
                print("BackgroundWorkerApiImpl: Saved task state: taskId=\(taskId)")
            }
            
            DispatchQueue.main.async {
                worker.close()
            }
            isSuccess = false
            
            // 如果工作器没有响应，在 2 秒后强制完成
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                semaphore.signal()
            }
        }
        
        // 生成任务 ID（用于状态保存）
        currentTaskId = "\(taskType)_\(UUID().uuidString)"
        UserDefaults.standard.set(currentTaskId, forKey: "background_task_current_id")
        print("BackgroundWorkerApiImpl: Starting task with ID: \(currentTaskId ?? "unknown")")
        
        // 在主线程运行工作器
        DispatchQueue.main.async {
            worker.run()
        }
        
        // 等待工作器完成
        semaphore.wait()
        
        // 清除当前任务 ID
        UserDefaults.standard.removeObject(forKey: "background_task_current_id")
        if isSuccess {
            UserDefaults.standard.set(Date(), forKey: "background_task_last_success")
        }
        
        task.setTaskCompleted(success: isSuccess)
        print("BackgroundWorkerApiImpl: Task completed with success: \(isSuccess)")
    }
}

