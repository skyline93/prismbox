import 'dart:async';
import 'dart:io';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';
import 'package:logging/logging.dart';

/// 重试配置
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });
}

/// 重试工具
class RetryHelper {
  static final Logger _log = Logger('RetryHelper');

  /// 执行带重试的操作
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    required RetryConfig config,
    required bool Function(dynamic error) shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = config.initialDelay;

    while (attempt < config.maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        // 检查是否应该重试
        if (!shouldRetry(error) || attempt >= config.maxRetries) {
          _log.warning('Retry failed after $attempt attempts', error);
          rethrow;
        }

        _log.info('Retrying operation (attempt $attempt/${config.maxRetries}) after ${delay.inSeconds}s');

        // 指数退避
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * config.backoffMultiplier).toInt(),
        );

        // 限制最大延迟
        if (delay > config.maxDelay) {
          delay = config.maxDelay;
        }
      }
    }

    throw Exception('Max retries exceeded');
  }

  /// 判断是否可重试的错误
  static bool isRetryableError(dynamic error) {
    // 网络错误可重试
    if (error is SocketException) return true;
    if (error is HttpException) return true;
    if (error is TimeoutException) return true;

    // 5xx服务器错误可重试
    if (error is ApiException) {
      final statusCode = error.statusCode;
      return statusCode >= 500 && statusCode < 600;
    }

    // 连接超时可重试
    if (error is TimeoutException) return true;

    return false;
  }
}

