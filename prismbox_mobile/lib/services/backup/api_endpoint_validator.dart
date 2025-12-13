// lib/services/backup/api_endpoint_validator.dart

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// API 端点验证器
/// 
/// **职责**：
/// - 验证上传端点是否可用
/// - 验证检查端点是否可用
/// - 提供端点健康检查
class ApiEndpointValidator {
  final ApiService _apiService;
  final Logger _logger = Logger('ApiEndpointValidator');

  // 端点路径
  static const String _uploadEndpoint = '/api/v1/media/upload-stream';
  static const String _checkAssetsEndpoint = '/api/v1/media/check_hashes';
  static const String _healthEndpoint = '/api/v1/health';

  ApiEndpointValidator({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  /// 验证上传端点
  /// 
  /// **验证方法**：
  /// - 发送 HEAD 请求检查端点是否存在
  /// - 或发送 OPTIONS 请求检查 CORS 支持
  /// 
  /// **返回**：验证结果
  Future<EndpointValidationResult> validateUploadEndpoint() async {
    return await _validateEndpoint(
      _uploadEndpoint,
      'upload',
    );
  }

  /// 验证检查端点
  /// 
  /// **验证方法**：
  /// - 发送 HEAD 请求检查端点是否存在
  /// 
  /// **返回**：验证结果
  Future<EndpointValidationResult> validateCheckEndpoint() async {
    return await _validateEndpoint(
      _checkAssetsEndpoint,
      'check',
    );
  }

  /// 验证端点（通用方法）
  /// 
  /// **参数**：
  /// - [endpoint] - 端点路径
  /// - [endpointName] - 端点名称（用于日志）
  /// 
  /// **返回**：验证结果
  Future<EndpointValidationResult> _validateEndpoint(
    String endpoint,
    String endpointName,
  ) async {
    try {
      final baseUrl = _apiService.endpoint;
      if (baseUrl == null || baseUrl.isEmpty) {
        return EndpointValidationResult(
          isValid: false,
          error: 'API endpoint not configured',
        );
      }

      final url = '$baseUrl$endpoint';
      _logger.info('Validating $endpointName endpoint: $url');

      // 尝试发送 HEAD 请求（轻量级检查）
      try {
        final response = await _apiService.dio.head(
          endpoint,
          options: Options(
            validateStatus: (status) {
              // 接受所有状态码（用于检查端点是否存在）
              return status != null;
            },
            followRedirects: false,
          ),
        );

        // 检查状态码
        if (response.statusCode != null) {
          final statusCode = response.statusCode!;
          
          // 2xx, 3xx, 4xx 都表示端点存在（只是可能不允许 HEAD 方法）
          if (statusCode >= 200 && statusCode < 500) {
            _logger.info(
              '$endpointName endpoint validation successful: '
              'statusCode=$statusCode',
            );
            return EndpointValidationResult(
              isValid: true,
              statusCode: statusCode,
            );
          }

          // 5xx 表示服务器错误
          if (statusCode >= 500) {
            return EndpointValidationResult(
              isValid: false,
              error: 'Server error: $statusCode',
              statusCode: statusCode,
            );
          }
        }
      } catch (e) {
        // HEAD 请求失败，尝试 OPTIONS 请求（CORS 预检）
        _logger.fine(
          'HEAD request failed for $endpointName endpoint, '
          'trying OPTIONS: $e',
        );

        try {
          final response = await _apiService.dio.request(
            endpoint,
            options: Options(
              method: 'OPTIONS',
              validateStatus: (status) {
                // 接受所有状态码
                return status != null;
              },
              followRedirects: false,
            ),
          );

          if (response.statusCode != null) {
            final statusCode = response.statusCode!;
            if (statusCode >= 200 && statusCode < 500) {
              _logger.info(
                '$endpointName endpoint validation successful via OPTIONS: '
                'statusCode=$statusCode',
              );
              return EndpointValidationResult(
                isValid: true,
                statusCode: statusCode,
              );
            }
          }
        } catch (e2) {
          _logger.warning(
            'OPTIONS request also failed for $endpointName endpoint: $e2',
          );
        }
      }

      // 如果 HEAD 和 OPTIONS 都失败，尝试 GET 请求（作为最后手段）
      _logger.fine(
        'Trying GET request as last resort for $endpointName endpoint',
      );

      try {
        final response = await _apiService.dio.get(
          endpoint,
          options: Options(
            validateStatus: (status) => true,
            followRedirects: false,
          ),
        );

        if (response.statusCode != null) {
          final statusCode = response.statusCode!;
          // 即使是 405 (Method Not Allowed) 也说明端点存在
          if (statusCode >= 200 && statusCode < 500) {
            _logger.info(
              '$endpointName endpoint validation successful via GET: '
              'statusCode=$statusCode',
            );
            return EndpointValidationResult(
              isValid: true,
              statusCode: statusCode,
            );
          }
        }
      } catch (e3) {
        _logger.warning(
          'GET request also failed for $endpointName endpoint: $e3',
        );
      }

      return EndpointValidationResult(
        isValid: false,
        error: 'Endpoint validation failed: all methods failed',
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to validate $endpointName endpoint: $e',
        e,
        stackTrace,
      );
      return EndpointValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }

  /// 验证所有端点
  /// 
  /// **返回**：所有端点的验证结果
  Future<AllEndpointsValidationResult> validateAllEndpoints() async {
    _logger.info('Validating all API endpoints');

    final uploadResult = await validateUploadEndpoint();
    final checkResult = await validateCheckEndpoint();

    final allValid = uploadResult.isValid && checkResult.isValid;

    _logger.info(
      'All endpoints validation completed: '
      'upload=${uploadResult.isValid}, '
      'check=${checkResult.isValid}',
    );

    return AllEndpointsValidationResult(
      uploadEndpoint: uploadResult,
      checkEndpoint: checkResult,
      allValid: allValid,
    );
  }

  /// 健康检查
  /// 
  /// **返回**：健康检查结果
  Future<bool> healthCheck() async {
    try {
      final baseUrl = _apiService.endpoint;
      if (baseUrl == null || baseUrl.isEmpty) {
        return false;
      }

      final url = '$baseUrl$_healthEndpoint';
      _logger.info('Performing health check: $url');

      final response = await _apiService.dio.get(
        _healthEndpoint,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final isHealthy = response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 500;

      _logger.info(
        'Health check completed: isHealthy=$isHealthy, '
        'statusCode=${response.statusCode}',
      );

      return isHealthy;
    } catch (e, stackTrace) {
      _logger.warning(
        'Health check failed: $e',
        e,
        stackTrace,
      );
      return false;
    }
  }
}

/// 端点验证结果
class EndpointValidationResult {
  final bool isValid;
  final String? error;
  final int? statusCode;

  EndpointValidationResult({
    required this.isValid,
    this.error,
    this.statusCode,
  });

  @override
  String toString() {
    if (isValid) {
      return 'EndpointValidationResult(isValid: true, statusCode: $statusCode)';
    } else {
      return 'EndpointValidationResult(isValid: false, error: $error, statusCode: $statusCode)';
    }
  }
}

/// 所有端点验证结果
class AllEndpointsValidationResult {
  final EndpointValidationResult uploadEndpoint;
  final EndpointValidationResult checkEndpoint;
  final bool allValid;

  AllEndpointsValidationResult({
    required this.uploadEndpoint,
    required this.checkEndpoint,
    required this.allValid,
  });

  @override
  String toString() {
    return 'AllEndpointsValidationResult('
        'uploadEndpoint: $uploadEndpoint, '
        'checkEndpoint: $checkEndpoint, '
        'allValid: $allValid)';
  }
}

