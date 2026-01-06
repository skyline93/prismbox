// lib/features/media_loading/mixins/cancellable_image_provider_mixin.dart

import 'dart:async';
import 'package:flutter/painting.dart';
import 'package:prismbox/features/media_loading/requests/image_request.dart';

/// 可取消的图片提供者 Mixin
/// 为 ImageProvider 添加取消加载的能力
mixin CancellableImageProviderMixin<T extends ImageProvider<T>> on ImageProvider<T> {
  /// 是否已取消
  bool _isCancelled = false;
  
  /// 当前的图片请求
  ImageRequest? _currentRequest;
  
  /// 当前的流订阅
  StreamSubscription? _subscription;
  
  /// 获取是否已取消
  bool get isCancelled => _isCancelled;
  
  /// 取消加载
  void cancel() {
    _isCancelled = true;
    _currentRequest?.cancel();
    _subscription?.cancel();
    _currentRequest = null;
    _subscription = null;
  }
  
  /// 重置取消状态（用于重新加载）
  void reset() {
    _isCancelled = false;
    _currentRequest = null;
    _subscription = null;
  }
  
  /// 设置当前请求
  void setCurrentRequest(ImageRequest? request) {
    _currentRequest = request;
  }
  
  /// 设置当前订阅
  void setCurrentSubscription(StreamSubscription? subscription) {
    _subscription?.cancel();
    _subscription = subscription;
  }
  
  /// 检查是否已取消，如果已取消则抛出异常
  void checkCancelled() {
    if (_isCancelled) {
      throw CancelledException('Image loading was cancelled');
    }
  }
}

/// 取消异常
class CancelledException implements Exception {
  final String message;
  
  CancelledException(this.message);
  
  @override
  String toString() => 'CancelledException: $message';
}

