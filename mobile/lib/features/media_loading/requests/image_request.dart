// lib/features/media_loading/requests/image_request.dart

import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:prismbox/features/media_loading/mixins/cancellable_image_provider_mixin.dart';

/// 图片请求抽象类
/// 用于封装加载逻辑，支持取消和进度报告
abstract class ImageRequest {
  /// 是否已取消
  bool _isCancelled = false;
  
  /// 获取是否已取消
  bool get isCancelled => _isCancelled;
  
  /// 取消请求
  void cancel() {
    _isCancelled = true;
    onCancel();
  }
  
  /// 取消时的回调（由子类实现）
  void onCancel();
  
  /// 检查是否已取消，如果已取消则抛出异常
  void checkCancelled() {
    if (_isCancelled) {
      throw CancelledException('Image request was cancelled');
    }
  }
  
  /// 加载图片
  /// 返回解码后的 Codec
  Future<ui.Codec> load(ImageDecoderCallback decode);
  
  /// 重置取消状态（用于重新加载）
  void reset() {
    _isCancelled = false;
  }
}

