import 'dart:io';
import 'package:dio/dio.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';
import 'package:logging/logging.dart';

/// API错误处理工具
class ApiErrorHandler {
  static final Logger _log = Logger('ApiErrorHandler');

  /// 处理API错误，转换为统一的ApiException
  static ApiException handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is SocketException) {
      return NetworkException('网络连接失败: ${error.message}', error);
    }

    if (error is HttpException) {
      return NetworkException('HTTP错误: ${error.message}', error);
    }

    if (error is TimeoutException) {
      return TimeoutException('请求超时', error);
    }

    _log.warning('Unknown error type: ${error.runtimeType}', error);
    return ApiException(500, '未知错误: $error', originalError: error);
  }

  /// 处理Dio错误
  static ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('请求超时');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        final message = _extractErrorMessage(error.response?.data) ?? '服务器错误';
        
        if (statusCode == 401) {
          return AuthenticationException(message);
        } else if (statusCode == 403) {
          return PermissionException(message);
        } else if (statusCode == 404) {
          return NotFoundException(message);
        } else if (statusCode >= 500) {
          return ServerException(message, error);
        } else {
          return ApiException(statusCode, message, originalError: error);
        }

      case DioExceptionType.cancel:
        return ApiException(0, '请求已取消', originalError: error);

      case DioExceptionType.connectionError:
        return NetworkException('网络连接错误: ${error.message}', error);

      case DioExceptionType.badCertificate:
        return SSLException('SSL证书验证失败', error);

      case DioExceptionType.unknown:
        return NetworkException('网络错误: ${error.message}', error);
    }
  }

  /// 从响应数据中提取错误消息
  static String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      // 优先使用后端 ApiResponse 格式的 message
      // 后端格式：{code: 1, message: "...", data: null}
      if (data['code'] != null && data['code'] != 0) {
        return data['message'] as String?;
      }

      // 兼容其他格式
      return data['message'] as String? ??
          data['error'] as String? ??
          data['msg'] as String?;
    }

    if (data is String) {
      return data;
    }

    return data.toString();
  }

  /// 获取用户友好的错误消息
  static String getErrorMessage(dynamic error) {
    final apiError = error is ApiException ? error : handleError(error);

    switch (apiError.statusCode) {
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '没有权限执行此操作';
      case 404:
        return '请求的资源不存在';
      case 495:
        return 'SSL证书验证失败';
      case 500:
      case 502:
      case 503:
        return '服务器错误，请稍后重试';
      case 504:
        return '请求超时，请稍后重试';
      default:
        return apiError.message;
    }
  }
}

