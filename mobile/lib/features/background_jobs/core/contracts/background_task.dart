// lib/features/background_jobs/core/contracts/background_task.dart

/// 所有具体后台任务处理器都必须实现的抽象接口。
/// 这定义了一个后台任务的契约，使其可以被通用调度器执行。
abstract class BackgroundTask {
  /// 执行后台任务的核心逻辑。
  /// [inputData] 是由 workmanager 传递的可选输入数据。
  /// 返回 `true` 表示任务成功，`false` 表示任务失败。
  Future<bool> execute(Map<String, dynamic>? inputData);
}
