// lib/features/media_loading/utils/retry_helper.dart

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:prismbox/features/media_loading/exceptions/network_image_exception.dart';

/// 重试助手
/// 提供指数退避重试机制
class RetryHelper {
  static final Logger _log = Logger('RetryHelper');
  
  /// 最大重试次数
  static const int maxRetries = 3;
  
  /// 基础延迟时间（秒）
  static const int baseDelaySeconds = 1;
  
  /// 执行带重试的操作
  /// 
  /// [operation] 要执行的操作
  /// [shouldRetry] 判断是否应该重试的函数（可选，默认只对网络错误重试）
  /// [onRetry] 重试前的回调（可选）
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    bool Function(Object error)? shouldRetry,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    int attempt = 0;
    
    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        // 判断是否应该重试
        final shouldRetryError = shouldRetry?.call(e) ?? _defaultShouldRetry(e);
        
        if (!shouldRetryError || attempt >= maxRetries) {
          _log.warning('Operation failed after $attempt retries', e, stackTrace);
          rethrow;
        }
        
        attempt++;
        final delay = baseDelaySeconds * attempt;
        
        _log.info('Operation failed, retrying in ${delay}s (attempt $attempt/$maxRetries)', e);
        
        // 调用重试回调
        onRetry?.call(attempt, e);
        
        // 等待后重试
        await Future.delayed(Duration(seconds: delay));
      }
    }
    
    // 理论上不会到达这里
    throw StateError('Retry logic error: exceeded max retries');
  }
  
  /// 默认的重试判断逻辑
  /// 只对网络错误和 5xx 错误重试
  static bool _defaultShouldRetry(Object error) {
    if (error is NetworkImageException) {
      return error.isRetryable && error.isNetworkError;
    }
    return false;
  }
}

