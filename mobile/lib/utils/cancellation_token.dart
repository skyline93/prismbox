// lib/utils/cancellation_token.dart

import 'dart:async';

/// 取消令牌
/// 用于取消异步操作
/// 
/// **用法**：
/// ```dart
/// final token = CancellationToken();
/// 
/// // 在异步操作中检查是否已取消
/// if (token.isCancelled) {
///   return;
/// }
/// 
/// // 取消操作
/// token.cancel();
/// ```
class CancellationToken {
  bool _isCancelled = false;
  final Completer<void> _completer = Completer<void>();

  /// 是否已取消
  bool get isCancelled => _isCancelled;

  /// 取消操作
  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      if (!_completer.isCompleted) {
        _completer.complete();
      }
    }
  }

  /// 等待取消（返回一个Future，当token被取消时完成）
  Future<void> get cancelled => _completer.future;

  /// 如果已取消，抛出 CancellationException
  void throwIfCancelled() {
    if (_isCancelled) {
      throw CancellationException('Operation was cancelled');
    }
  }
}

/// 取消异常
class CancellationException implements Exception {
  final String message;

  CancellationException(this.message);

  @override
  String toString() => 'CancellationException: $message';
}

