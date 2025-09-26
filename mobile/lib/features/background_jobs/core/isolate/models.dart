/// 从主 Isolate 发送到后台 Isolate 的作业请求
class IsolateJob {
  /// 任务名称，用于在 Isolate 中路由到对应的 Handler
  final String taskName;

  /// 任务需要的数据
  final dynamic payload;

  /// 可选的请求 ID，用于将结果与请求匹配
  final String? requestId;

  IsolateJob(this.taskName, {this.payload, this.requestId});
}

/// 通用管理命令
enum IsolateCommand { dispose }

/// 作业状态枚举
enum JobStatus { running, success, failure }

/// 从后台 Isolate 发送回主 Isolate 的作业结果或状态
class IsolateJobResult {
  final JobStatus status;
  final String? requestId; // 对应请求的 ID
  final dynamic data; // 如果成功，这里是结果；如果失败，这里是错误信息

  IsolateJobResult(this.status, {this.data, this.requestId});
}
