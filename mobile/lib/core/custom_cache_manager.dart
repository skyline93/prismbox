// lib/core/custom_cache_manager.dart

import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/providers.dart';

/// Riverpod Provider: 自定义 CacheManager
final customCacheManagerProvider = Provider<CacheManager>((ref) {
  final dioClient = ref.read(dioClientProvider);

  return CacheManager(
    Config(
      'customImageCacheKey',
      stalePeriod: const Duration(days: 15), // 缓存有效期
      maxNrOfCacheObjects: 500, // 最大缓存文件数
      fileService: DioHttpFileService(dioClient.fileDio),
    ),
  );
});

/// 使用 Dio 来下载网络文件，适配 FileService 接口
class DioHttpFileService implements FileService {
  final dio.Dio _dio;

  /// 注意：新版接口要求是非空 int
  @override
  int concurrentFetches = 5;

  DioHttpFileService(this._dio);

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get<Uint8List>(
        url,
        options: dio.Options(
          headers: headers,
          responseType: dio.ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return _DioFileServiceResponse(response);
      } else {
        throw HttpExceptionWithStatus(
          response.statusCode ?? 0,
          'Invalid statusCode: ${response.statusCode}',
          uri: Uri.parse(url),
        );
      }
    } on dio.DioException catch (e) {
      throw HttpExceptionWithStatus(
        e.response?.statusCode ?? 0,
        e.message ?? 'Failed to download file with Dio',
        uri: Uri.parse(url),
      );
    } catch (e) {
      throw Exception('Failed to download file with Dio: $e');
    }
  }
}

/// FileServiceResponse 的 Dio 实现
class _DioFileServiceResponse implements FileServiceResponse {
  final dio.Response<Uint8List> _response;

  _DioFileServiceResponse(this._response);

  @override
  Stream<List<int>> get content => Stream.value(_response.data!);

  @override
  int get statusCode => _response.statusCode ?? 0;

  @override
  int? get contentLength => _response.data?.length;

  /// 注意：新版接口要求返回非空 String
  @override
  String get fileExtension {
    final contentType = _response.headers.value('content-type');
    if (contentType != null) {
      if (contentType.contains('jpeg')) return '.jpg';
      if (contentType.contains('png')) return '.png';
      if (contentType.contains('gif')) return '.gif';
      if (contentType.contains('webp')) return '.webp';
    }
    return '.dat'; // fallback 默认值
  }

  @override
  String? get eTag => _response.headers.value('etag');

  /// 新版接口确实有 validTill，所以加上 @override
  @override
  DateTime get validTill => _getValidTill();

  DateTime _getValidTill() {
    final cacheControl = _response.headers.value('cache-control');
    if (cacheControl != null) {
      final maxAgeMatch = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
      if (maxAgeMatch != null) {
        final seconds = int.parse(maxAgeMatch.group(1)!);
        if (seconds > 0) {
          return DateTime.now().add(Duration(seconds: seconds));
        }
      }
    }
    // 默认缓存 7 天
    return DateTime.now().add(const Duration(days: 7));
  }
}
