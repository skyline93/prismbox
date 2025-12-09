// lib/features/media_loading/exceptions/network_image_exception.dart

/// 网络图片异常
/// 表示加载网络图片时发生的错误
class NetworkImageException implements Exception {
  /// 错误消息
  final String message;
  
  /// HTTP 状态码（如果有）
  final int? statusCode;
  
  /// 请求的 URL
  final String? url;
  
  /// 是否为可重试的错误（5xx 或网络错误）
  final bool isRetryable;
  
  NetworkImageException({
    required this.message,
    this.statusCode,
    this.url,
    this.isRetryable = true,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer('NetworkImageException: $message');
    if (statusCode != null) {
      buffer.write(' (statusCode: $statusCode)');
    }
    if (url != null) {
      buffer.write(' (url: $url)');
    }
    return buffer.toString();
  }
  
  /// 判断是否为网络错误（可重试）
  bool get isNetworkError => statusCode == null || (statusCode! >= 500 && statusCode! < 600);
  
  /// 判断是否为客户端错误（不可重试）
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;
}

