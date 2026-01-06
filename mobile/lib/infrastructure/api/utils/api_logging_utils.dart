// lib/infrastructure/api/utils/api_logging_utils.dart

import 'dart:convert';

/// API 日志工具类
/// 提供统一的日志格式化、敏感信息处理等功能
class ApiLoggingUtils {
  // 常量定义
  static const int maxResponseBodyLength = 2000;
  
  // 需要隐藏的敏感字段
  static const List<String> sensitiveFields = [
    'password',
    'token',
    'accessToken',
    'refreshToken',
    'authorization',
    'x-prismbox-user-token',
  ];

  /// 获取 HTTP 状态码描述
  static String getStatusMessage(int? statusCode) {
    if (statusCode == null) return '';
    
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        return '';
    }
  }

  /// 格式化 JSON 数据（带敏感信息过滤）
  static String formatJson(dynamic data, {bool sanitize = true}) {
    try {
      if (data is String) {
        final decoded = jsonDecode(data);
        return formatJson(decoded, sanitize: sanitize);
      } else if (data is Map || data is List) {
        final processed = sanitize ? sanitizeData(data) : data;
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(processed);
      } else {
        return data.toString();
      }
    } catch (e) {
      return data.toString();
    }
  }

  /// 格式化响应体
  static String formatResponseBody(dynamic data, {bool sanitize = true}) {
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return formatJson(decoded, sanitize: sanitize);
      } catch (e) {
        return data;
      }
    } else {
      return formatJson(data, sanitize: sanitize);
    }
  }

  /// 隐藏敏感信息
  static dynamic sanitizeData(dynamic data) {
    if (data is Map) {
      final sanitized = <String, dynamic>{};
      data.forEach((key, value) {
        final keyStr = key.toString().toLowerCase();
        if (sensitiveFields.any((field) => keyStr.contains(field.toLowerCase()))) {
          sanitized[key.toString()] = '***HIDDEN***';
        } else if (value is Map || value is List) {
          sanitized[key.toString()] = sanitizeData(value);
        } else {
          sanitized[key.toString()] = value;
        }
      });
      return sanitized;
    } else if (data is List) {
      return data.map((item) => sanitizeData(item)).toList();
    } else {
      return data;
    }
  }

  /// 隐藏请求头中的敏感信息
  static Map<String, dynamic> sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = <String, dynamic>{};
    headers.forEach((key, value) {
      final keyStr = key.toLowerCase();
      if (sensitiveFields.any((field) => keyStr.contains(field.toLowerCase()))) {
        sanitized[key] = '***HIDDEN***';
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  /// 隐藏刷新响应中的敏感信息（专门处理 refresh token 响应）
  static Map<String, dynamic> sanitizeRefreshResponse(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    data.forEach((key, value) {
      if (key == 'data' && value is Map<String, dynamic>) {
        final sanitizedData = <String, dynamic>{};
        value.forEach((k, v) {
          if (k == 'access_token' || k == 'refresh_token') {
            sanitizedData[k] = '***HIDDEN***';
          } else {
            sanitizedData[k] = v;
          }
        });
        sanitized[key] = sanitizedData;
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  /// 截断过长的响应体
  static String truncateResponseBody(String body) {
    if (body.length > maxResponseBodyLength) {
      return '${body.substring(0, maxResponseBodyLength)}...\n  [响应体过长，已截断。完整长度: ${body.length} 字符]';
    }
    return body;
  }
}

