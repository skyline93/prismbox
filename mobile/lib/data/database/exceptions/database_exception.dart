// lib/data/database/exceptions/database_exception.dart

/// 数据库错误类型
enum DatabaseErrorType {
  /// 连接失败
  connectionFailed,
  
  /// 迁移失败
  migrationFailed,
  
  /// 约束违反
  constraintViolation,
  
  /// 事务失败
  transactionFailed,
  
  /// 查询失败
  queryFailed,
}

/// 数据库异常
class DatabaseException implements Exception {
  final DatabaseErrorType type;
  final String message;
  final dynamic originalError;
  
  DatabaseException({
    required this.type,
    required this.message,
    this.originalError,
  });
  
  @override
  String toString() {
    return 'DatabaseException(type: $type, message: $message, originalError: $originalError)';
  }
}

