import BackgroundTasks
import Flutter

enum BackgroundTaskType {
    case refresh
    case processing
}

/*
 * DEBUG: Testing Background Tasks in Xcode
 * 
 * To test background task functionality during development:
 * 1. Pause the application in Xcode debugger
 * 2. In the debugger console, enter one of the following commands:
 
 ## For background refresh (short-running sync):
 
 e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.u163.glf9832.prismbox.background.refreshUpload"]
 
 ## For background processing (long-running upload):
 
 e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.u163.glf9832.prismbox.background.processingUpload"]

 * To simulate task expiration (useful for testing expiration handlers):
 
 e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.u163.glf9832.prismbox.background.refreshUpload"]
 
 e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.u163.glf9832.prismbox.background.processingUpload"]

 * 3. Resume the application to see the background code execute
 * 
 * NOTE: This must be tested on a physical device, not in the simulator.
 * In testing, only the background processing task can be reliably simulated.
 * These commands submit the respective task to BGTaskScheduler for immediate processing.
 * Use the expiration commands to test how the app handles iOS terminating background tasks.
 */

/// The background worker which creates a new Flutter VM, communicates with it
/// to run the backup job, and then finishes execution and calls back to its callback handler.
/// This class manages a separate Flutter engine instance for background execution,
/// independent of the main UI Flutter engine.
class BackgroundWorker: BackgroundWorkerBgHostApi {
    private let taskType: BackgroundTaskType
    /// The maximum number of seconds to run the task before timing out
    private let maxSeconds: Int?
    /// Callback function to invoke when the background task completes
    private let completionHandler: (_ success: Bool) -> Void
    
    /// The Flutter engine created specifically for background execution.
    /// This is a separate instance from the main Flutter engine that handles the UI.
    /// It operates in its own isolate and doesn't share memory with the main engine.
    /// Must be properly started, registered, and torn down during background execution.
    private let engine = FlutterEngine(name: "BackgroundPrismBox")
    
    /// Used to call methods on the flutter side
    private var flutterApi: BackgroundWorkerFlutterApi?
    
    /// Flag to track whether the background task has completed to prevent duplicate completions
    private var isComplete = false
    
    /**
     * Initializes a new background worker with the specified task type and execution constraints.
     * Creates a new Flutter engine instance for background execution and sets up the necessary
     * communication channels between native iOS and Flutter code.
     *
     * - Parameters:
     *   - taskType: The type of background task to execute (refresh or processing)
     *   - maxSeconds: Optional maximum execution time in seconds before the task is cancelled
     *   - completionHandler: Callback function invoked when the task completes, with success status
     */
    init(taskType: BackgroundTaskType, maxSeconds: Int?, completionHandler: @escaping (_ success: Bool) -> Void) {
        self.taskType = taskType
        self.maxSeconds = maxSeconds
        self.completionHandler = completionHandler
        // Should be initialized only after the engine starts running
        self.flutterApi = nil
    }
    
    /**
     * Starts the background Flutter engine and begins execution of the background task.
     * Retrieves the callback handle from UserDefaults, looks up the Flutter callback,
     * starts the engine, and sets up a timeout timer if specified.
     */
    func run() {
        // Start the Flutter engine with the specified callback as the entry point
        let isRunning = engine.run(
            withEntrypoint: "backgroundSyncNativeEntrypoint",
            libraryURI: "package:prismbox/features/background_backup/service/background_worker_bg_service.dart"
        )
        
        // Verify that the Flutter engine started successfully
        if !isRunning {
            complete(success: false)
            return
        }
        
        // Register plugins in the new engine
        GeneratedPluginRegistrant.register(with: engine)
        // TODO: Register custom plugins if needed
        // AppDelegate.registerPlugins(with: engine)
        
        flutterApi = BackgroundWorkerFlutterApi(binaryMessenger: engine.binaryMessenger)
        BackgroundWorkerBgHostApiSetup.setUp(binaryMessenger: engine.binaryMessenger, api: self)
        
        // Set up a timeout timer if maxSeconds was specified to prevent runaway background tasks
        if let maxSeconds = maxSeconds {
            // Schedule a timer to cancel the task after the specified timeout period
            Timer.scheduledTimer(withTimeInterval: TimeInterval(maxSeconds), repeats: false) { _ in
                self.close()
            }
        }
    }
    
    /**
     * Called by the Flutter side when it has finished initialization and is ready to receive commands.
     * Routes the appropriate task type (refresh or processing) to the corresponding Flutter method.
     * This method acts as a bridge between the native iOS background task system and Flutter.
     */
    func onInitialized() throws {
        flutterApi?.onIosUpload(
            isRefresh: self.taskType == .refresh,
            maxSeconds: maxSeconds.map { Int64($0) },
            completion: { result in
                self.handleHostResult(result: result)
            }
        )
    }
    
    /**
     * Called when the background task completes successfully.
     * This is called by the Flutter side to notify that the task has finished.
     */
    func onCompleted() throws {
        complete(success: true)
    }
    
    /**
     * Updates the progress of the background task.
     * Currently just logs the progress for debugging purposes.
     */
    func updateProgress(uploadedCount: Int64, totalCount: Int64, currentFileName: String?) throws {
        // TODO: Implement progress notification if needed
        print("Upload progress: \(uploadedCount)/\(totalCount) - \(currentFileName ?? "unknown")")
    }
    
    /**
     * 检查内容是否已变化（Android 专用）
     * iOS 上总是返回 false，因为 iOS 使用不同的机制
     */
    func hasContentChanged() throws -> Bool {
        // iOS 不需要这个功能，因为 iOS 使用 BGTaskScheduler 来调度任务
        // 而不是基于内容变化触发
        return false
    }
    
    /**
     * Cancels the currently running background task, either due to timeout or external request.
     * Sends a cancel signal to the Flutter side and sets up a fallback timer to ensure
     * the completion handler is eventually called even if Flutter doesn't respond.
     */
    func close() {
        if isComplete {
            return
        }

        flutterApi?.cancel { result in
            self.complete(success: false)
        }

        // Fallback safety mechanism: ensure completion is called within 2 seconds
        // This prevents the background task from hanging indefinitely if Flutter doesn't respond
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            self.complete(success: false)
        }
    }
    
    /**
     * Handles the result from Flutter API calls and determines the success/failure status.
     * Converts Flutter's Result type to a simple boolean success indicator for task completion.
     *
     * - Parameter result: The result returned from a Flutter API call
     */
    private func handleHostResult(result: Result<Void, BackgroundWorkerError>) {
        if isComplete {
            return
        }

        switch result {
        case .success:
            complete(success: true)
        case .failure(let error):
            print("BackgroundWorker: Task failed with error: \(error.code) - \(error.message ?? "unknown")")
            complete(success: false)
        }
    }
    
    /**
     * Completes the background task and invokes the completion handler.
     * Ensures the completion handler is only called once to prevent duplicate notifications.
     *
     * - Parameter success: Whether the task completed successfully or not
     */
    private func complete(success: Bool) {
        if isComplete {
            return
        }
        
        isComplete = true
        
        // Clean up the Flutter engine
        engine.destroyContext()
        
        // Invoke the completion handler to signal task completion
        completionHandler(success)
    }
}

