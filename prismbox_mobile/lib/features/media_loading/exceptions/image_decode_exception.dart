// lib/features/media_loading/exceptions/image_decode_exception.dart

/// 图片解码异常
/// 表示解码图片数据时发生的错误
class ImageDecodeException implements Exception {
  /// 错误消息
  final String message;
  
  /// 数据源（文件路径或 URL）
  final String? source;
  
  /// 原始异常（如果有）
  final Object? originalException;
  
  ImageDecodeException({
    required this.message,
    this.source,
    this.originalException,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer('ImageDecodeException: $message');
    if (source != null) {
      buffer.write(' (source: $source)');
    }
    return buffer.toString();
  }
}

