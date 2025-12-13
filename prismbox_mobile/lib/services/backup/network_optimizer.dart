// lib/services/backup/network_optimizer.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// 网络优化器
/// 
/// **职责**：
/// - 连接复用和连接池管理
/// - 请求合并（批量检查 checksum）
/// - 智能重试机制
/// 
/// **优化策略**：
/// - 使用 Dio 的连接池功能
/// - 批量请求合并，减少网络往返
/// - 智能重试，避免无效重试
class NetworkOptimizer {
  final ApiService _apiService;
  final Logger _logger = Logger('NetworkOptimizer');

  // 连接池配置
  static const int _maxConnectionsPerHost = 6;
  static const Duration _idleTimeout = Duration(seconds: 30);

  // 批量请求配置
  static const int _batchSize = 100; // 每批最多 100 个

  NetworkOptimizer({
    required ApiService apiService,
  }) : _apiService = apiService {
    _configureConnectionPool();
  }

  /// 配置连接池
  void _configureConnectionPool() {
    try {
      final dio = _apiService.dio;
      
      // 检查是否已经配置了 IOHttpClientAdapter
      if (dio.httpClientAdapter is IOHttpClientAdapter) {
        final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
        
        // 如果还没有配置 createHttpClient，则配置它
        if (adapter.createHttpClient == null) {
          adapter.createHttpClient = () {
            final client = HttpClient();
            client.maxConnectionsPerHost = _maxConnectionsPerHost;
            client.idleTimeout = _idleTimeout;
            client.autoUncompress = true;
            return client;
          };
          
          _logger.info(
            'Connection pool configured: maxConnectionsPerHost=$_maxConnectionsPerHost, '
            'idleTimeout=${_idleTimeout.inSeconds}s',
          );
        } else {
          // 已经配置过了，记录日志
          _logger.info(
            'Connection pool already configured by ApiService: '
            'maxConnectionsPerHost=$_maxConnectionsPerHost, '
            'idleTimeout=${_idleTimeout.inSeconds}s',
          );
        }
      } else {
        _logger.warning(
          'Dio adapter is not IOHttpClientAdapter, connection pool configuration skipped',
        );
      }
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to configure connection pool',
        e,
        stackTrace,
      );
    }
  }

  /// 批量检查资产是否存在（优化版本）
  /// 
  /// **参数**：
  /// - [checksums] - checksum 列表
  /// 
  /// **返回**：已存在的 checksum 集合
  /// 
  /// **优化策略**：
  /// - 分批检查（每批最多 100 个）
  /// - 使用连接池复用连接
  /// - 支持超时和降级策略
  Future<Set<String>> batchCheckAssetsExist(
    List<String> checksums,
  ) async {
    if (checksums.isEmpty) {
      return {};
    }

    _logger.info('Batch checking assets exist: count=${checksums.length}');

    final existingChecksums = <String>{};

    try {
      // 分批检查
      for (int i = 0; i < checksums.length; i += _batchSize) {
        final batch = checksums.skip(i).take(_batchSize).toList();

        try {
          final batchResult = await _checkBatchWithRetry(batch);
          existingChecksums.addAll(batchResult);
        } catch (e, stackTrace) {
          _logger.warning(
            'Failed to check batch ${i ~/ _batchSize + 1}: $e',
            e,
            stackTrace,
          );
          // 降级策略：跳过本批次，继续处理下一批次
        }
      }

      _logger.info(
        'Batch check completed: total=${checksums.length}, '
        'existing=${existingChecksums.length}',
      );

      return existingChecksums;
    } catch (e, stackTrace) {
      _logger.severe('Batch check failed', e, stackTrace);
      // 降级策略：返回空集合，允许继续上传
      return {};
    }
  }

  /// 检查批次（带重试）
  /// 
  /// **参数**：
  /// - [checksums] - checksum 列表（一批）
  /// 
  /// **返回**：已存在的 checksum 集合
  Future<Set<String>> _checkBatchWithRetry(List<String> checksums) async {
    const maxRetries = 3;
    const timeout = Duration(seconds: 30);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final endpoint = _apiService.endpoint ?? '';
        final url = '$endpoint/api/v1/media/check_hashes';

        final headers = ApiService.getRequestHeaders();
        headers['Content-Type'] = 'application/json';

        final response = await _apiService.dio
            .post(
              url,
              data: {'hashes': checksums},
              options: Options(headers: headers),
            )
            .timeout(timeout);

        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          // 响应拦截器已经提取了 data 字段，所以 response.data 直接是业务数据
          final data = response.data as Map<String, dynamic>?;
          if (data != null) {
            final existing = data['existing_hashes'] as List<dynamic>?;
          if (existing != null) {
            return existing.cast<String>().toSet();
            }
          }
        }

        return {};
      } catch (e) {
        if (attempt < maxRetries - 1) {
          // 指数退避重试
          final delay = Duration(milliseconds: 1000 * (1 << attempt));
          _logger.info(
            'Batch check failed, retrying in ${delay.inMilliseconds}ms '
            '(attempt ${attempt + 1}/$maxRetries)',
          );
          await Future.delayed(delay);
        } else {
          rethrow;
        }
      }
    }

    return {};
  }

  /// 获取连接池统计信息
  /// 
  /// **返回**：连接池统计信息（用于监控和调试）
  Map<String, dynamic> getConnectionPoolStats() {
    // 注意：Dio 不直接提供连接池统计信息
    // 这里返回配置信息
    return {
      'maxConnectionsPerHost': _maxConnectionsPerHost,
      'idleTimeout': _idleTimeout.inSeconds,
      'batchSize': _batchSize,
    };
  }
}

