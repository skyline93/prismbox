// lib/services/backup/error_handler.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';

/// 统一错误处理器
/// 
/// **职责**：
/// - 统一错误类型定义和分类
/// - 错误格式化（用户友好提示）
/// - 错误日志记录
/// 
/// **设计原则**：
/// - 所有备份相关错误都通过此处理器处理
/// - 提供统一的错误分类和格式化接口
/// - 支持错误通知和日志记录
class BackupErrorHandler {
  final Logger _logger = Logger('BackupErrorHandler');

  /// 处理错误并返回格式化后的错误信息
  /// 
  /// **参数**：
  /// - [error] - 原始错误对象
  /// - [context] - 错误上下文（可选，用于日志记录）
  /// 
  /// **返回**：BackupError（格式化后的错误）
  BackupError handleError(
    dynamic error, {
    String? context,
  }) {
    final backupError = _classifyError(error);
    
    _logger.warning(
      'Backup error${context != null ? " in $context" : ""}: '
      '${backupError.type}, ${backupError.message}',
      error,
      StackTrace.current,
    );

    return backupError;
  }

  /// 分类错误
  /// 
  /// **参数**：
  /// - [error] - 原始错误对象
  /// 
  /// **返回**：BackupError（分类后的错误）
  BackupError _classifyError(dynamic error) {
    // 网络错误
    if (error is SocketException) {
      return BackupError(
        type: BackupErrorType.network,
        message: '网络连接失败，请检查网络设置',
        originalError: error,
        isRetryable: true,
      );
    }

    // Dio 错误
    if (error is DioException) {
      return _classifyDioError(error);
    }

    // 文件系统错误
    if (error is FileSystemException) {
      return BackupError(
        type: BackupErrorType.local,
        message: '文件访问失败：${error.message}',
        originalError: error,
        isRetryable: false,
      );
    }

    // 超时错误（自定义 TimeoutException）
    if (error is TimeoutException) {
      return BackupError(
        type: BackupErrorType.timeout,
        message: '操作超时，请稍后重试',
        originalError: error,
        isRetryable: true,
      );
    }

    // 其他错误
    return BackupError(
      type: BackupErrorType.unknown,
      message: error.toString(),
      originalError: error,
      isRetryable: false,
    );
  }

  /// 分类 Dio 错误
  BackupError _classifyDioError(DioException error) {
    final statusCode = error.response?.statusCode;

    // 认证错误
    if (statusCode == 401) {
      return BackupError(
        type: BackupErrorType.authentication,
        message: '认证失败，请重新登录',
        originalError: error,
        isRetryable: false,
      );
    }

    // 权限错误
    if (statusCode == 403) {
      return BackupError(
        type: BackupErrorType.permission,
        message: '权限不足，无法执行此操作',
        originalError: error,
        isRetryable: false,
      );
    }

    // 客户端错误（4xx）
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return BackupError(
        type: BackupErrorType.client,
        message: '请求错误 ($statusCode)',
        originalError: error,
        isRetryable: false,
      );
    }

    // 服务器错误（5xx）
    if (statusCode != null && statusCode >= 500) {
      return BackupError(
        type: BackupErrorType.server,
        message: '服务器错误 ($statusCode)，请稍后重试',
        originalError: error,
        isRetryable: true,
      );
    }

    // 网络连接错误
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return BackupError(
        type: BackupErrorType.timeout,
        message: '网络超时，请检查网络连接',
        originalError: error,
        isRetryable: true,
      );
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return BackupError(
        type: BackupErrorType.network,
        message: '网络连接失败，请检查网络设置',
        originalError: error,
        isRetryable: true,
      );
    }

    // 其他 Dio 错误
    return BackupError(
      type: BackupErrorType.unknown,
      message: '网络请求失败：${error.message}',
      originalError: error,
      isRetryable: false,
    );
  }

  /// 格式化错误消息（用户友好）
  /// 
  /// **参数**：
  /// - [error] - BackupError 对象
  /// 
  /// **返回**：用户友好的错误消息
  String formatErrorMessage(BackupError error) {
    return error.message;
  }

  /// 判断错误是否可重试
  /// 
  /// **参数**：
  /// - [error] - BackupError 对象
  /// 
  /// **返回**：是否可重试
  bool isRetryable(BackupError error) {
    return error.isRetryable;
  }
}

/// 备份错误类型
enum BackupErrorType {
  /// 网络错误（可重试）
  network,

  /// 认证错误（不可重试）
  authentication,

  /// 权限错误（不可重试）
  permission,

  /// 服务器错误（5xx 可重试，4xx 不可重试）
  server,

  /// 客户端错误（4xx，不可重试）
  client,

  /// 本地错误（文件不存在、权限不足等，不可重试）
  local,

  /// 超时错误（可重试）
  timeout,

  /// 取消错误（不可重试）
  cancelled,

  /// 未知错误（不可重试）
  unknown,
}

/// 备份错误
class BackupError {
  /// 错误类型
  final BackupErrorType type;

  /// 错误消息（用户友好）
  final String message;

  /// 原始错误对象
  final dynamic originalError;

  /// 是否可重试
  final bool isRetryable;

  /// 错误时间戳
  final DateTime timestamp;

  BackupError({
    required this.type,
    required this.message,
    this.originalError,
    required this.isRetryable,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'BackupError(type: $type, message: $message, '
        'isRetryable: $isRetryable, timestamp: $timestamp)';
  }
}

