import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// 端点发现服务
class EndpointDiscovery {
  final ApiService _apiService;
  final Logger _log = Logger('EndpointDiscovery');

  EndpointDiscovery(this._apiService);

  /// 发现并验证端点
  Future<String> discoverAndValidate(String serverUrl) async {
    // 清理URL
    String url = _sanitizeUrl(serverUrl);

    // 尝试well-known发现
    final wellKnownEndpoint = await getWellKnownEndpoint(url);
    if (wellKnownEndpoint.isNotEmpty) {
      url = _sanitizeUrl(wellKnownEndpoint);
    }

    // 验证端点可用性
    if (!await validateEndpoint(url)) {
      throw ApiException(503, '服务器不可达');
    }

    return url;
  }

  /// 获取well-known端点
  Future<String> getWellKnownEndpoint(String baseUrl) async {
    final client = http.Client();

    try {
      final headers = {
        'Accept': 'application/json',
        ...ApiService.getRequestHeaders(),
      };

      final uri = Uri.parse('$baseUrl/.well-known/prismbox');
      final response = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final apiData = data['api'] as Map<String, dynamic>?;
        if (apiData != null) {
          final endpoint = apiData['endpoint']?.toString() ?? '';

          // 处理相对路径和绝对路径
          if (endpoint.startsWith('/')) {
            // 相对路径：拼接基础URL
            return '$baseUrl$endpoint';
          } else if (endpoint.isNotEmpty) {
            // 绝对路径：直接返回
            return endpoint;
          }
        }
      }
    } catch (e) {
      _log.warning('Could not locate /.well-known/prismbox at $baseUrl: $e');
    } finally {
      client.close();
    }

    return '';
  }

  /// 验证端点可用性
  Future<bool> validateEndpoint(String endpoint) async {
    // 确保URL以/api结尾
    String url = endpoint;
    if (!url.endsWith('/api')) {
      if (!url.endsWith('/')) {
        url += '/';
      }
      url += 'api';
    }

    try {
      // 临时设置端点
      _apiService.setEndpoint(url);

      // 调用pingServer验证（超时5秒）
      await _apiService.pingServer().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('服务器响应超时');
        },
      );

      return true;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } catch (error, stackTrace) {
      _log.severe(
        'Error while checking server availability',
        error,
        stackTrace,
      );
      return false;
    }
  }

  /// 清理URL
  String _sanitizeUrl(String url) {
    url = url.trim();
    
    // 移除末尾的斜杠
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    // 如果没有协议，添加https://
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    return url;
  }
}

