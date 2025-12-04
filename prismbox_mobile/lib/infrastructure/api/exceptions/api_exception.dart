/// API异常基类
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  ApiException(
    this.statusCode,
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}

/// 网络连接错误
class NetworkException extends ApiException {
  NetworkException(String message, [dynamic originalError])
      : super(503, message, originalError: originalError);
}

/// SSL/TLS错误
class SSLException extends ApiException {
  SSLException(String message, [dynamic originalError])
      : super(495, message, originalError: originalError);
}

/// 超时错误
class TimeoutException extends ApiException {
  TimeoutException(String message, [dynamic originalError])
      : super(504, message, originalError: originalError);
}

/// 认证错误
class AuthenticationException extends ApiException {
  AuthenticationException(String message)
      : super(401, message);
}

/// 权限错误
class PermissionException extends ApiException {
  PermissionException(String message)
      : super(403, message);
}

/// 资源不存在错误
class NotFoundException extends ApiException {
  NotFoundException(String message)
      : super(404, message);
}

/// 服务器错误
class ServerException extends ApiException {
  ServerException(String message, [dynamic originalError])
      : super(500, message, originalError: originalError);
}

