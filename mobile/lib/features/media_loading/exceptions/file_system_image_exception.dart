// lib/features/media_loading/exceptions/file_system_image_exception.dart

/// 文件系统图片异常
/// 表示读取本地文件时发生的错误
class FileSystemImageException implements Exception {
  /// 错误消息
  final String message;
  
  /// 文件路径
  final String? filePath;
  
  /// 错误代码（如果有）
  final String? errorCode;
  
  FileSystemImageException({
    required this.message,
    this.filePath,
    this.errorCode,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer('FileSystemImageException: $message');
    if (filePath != null) {
      buffer.write(' (filePath: $filePath)');
    }
    if (errorCode != null) {
      buffer.write(' (errorCode: $errorCode)');
    }
    return buffer.toString();
  }
}

