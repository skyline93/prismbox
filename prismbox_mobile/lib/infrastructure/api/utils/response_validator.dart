// lib/infrastructure/api/utils/response_validator.dart

import 'package:dio/dio.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';

/// API 响应验证工具类
/// 用于统一验证和提取 API 响应数据
class ResponseValidator {
  /// 验证响应数据并提取为 Map
  /// 
  /// [response] Dio 响应对象
  /// 
  /// 返回验证后的 Map<String, dynamic>
  /// 
  /// 如果数据为空或格式错误，抛出 [ApiException]
  static Map<String, dynamic> validateAndExtract(Response response) {
    if (response.data == null) {
      throw ApiException(500, '服务器返回数据为空');
    }

    if (response.data is! Map<String, dynamic>) {
      throw ApiException(
        500,
        '服务器返回数据格式错误: ${response.data.runtimeType}',
      );
    }

    return response.data as Map<String, dynamic>;
  }

  /// 验证响应数据并提取为 Map（允许 null）
  /// 
  /// 用于某些接口可能返回 null data 的情况（如 logout）
  /// 
  /// [response] Dio 响应对象
  /// 
  /// 返回验证后的 Map<String, dynamic>?，如果为 null 则返回 null
  static Map<String, dynamic>? validateAndExtractNullable(Response response) {
    if (response.data == null) {
      return null;
    }

    if (response.data is! Map<String, dynamic>) {
      throw ApiException(
        500,
        '服务器返回数据格式错误: ${response.data.runtimeType}',
      );
    }

    return response.data as Map<String, dynamic>;
  }
}

