// lib/features/remote_sync/exceptions/remote_sync_exception.dart

/// 远程同步异常基类
class RemoteSyncException implements Exception {
  final String message;
  final Object? cause;

  const RemoteSyncException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'RemoteSyncException: $message\nCaused by: $cause';
    }
    return 'RemoteSyncException: $message';
  }
}

/// 网络异常
class NetworkException extends RemoteSyncException {
  const NetworkException(String message, [Object? cause])
      : super(message, cause);
}

/// 认证异常
class AuthenticationException extends RemoteSyncException {
  const AuthenticationException([String? message])
      : super(message ?? '认证失败，请重新登录');
}

/// 服务器异常
class ServerException extends RemoteSyncException {
  const ServerException(String message, [Object? cause])
      : super(message, cause);
}

/// 数据解析异常
class DataParseException extends RemoteSyncException {
  const DataParseException(String message, [Object? cause])
      : super(message, cause);
}

