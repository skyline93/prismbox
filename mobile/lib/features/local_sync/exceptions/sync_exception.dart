// lib/features/local_sync/exceptions/sync_exception.dart

/// 同步异常基类
class SyncException implements Exception {
  final String message;
  final Object? cause;

  const SyncException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'SyncException: $message\nCaused by: $cause';
    }
    return 'SyncException: $message';
  }
}

/// 权限异常
class PermissionException extends SyncException {
  const PermissionException([String? message])
      : super(message ?? '相册访问权限被拒绝');
}

/// 数据库异常
class DatabaseException extends SyncException {
  const DatabaseException(String message, [Object? cause])
      : super(message, cause);
}

/// 系统相册异常
class PhotoManagerException extends SyncException {
  const PhotoManagerException(String message, [Object? cause])
      : super(message, cause);
}

