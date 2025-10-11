// lib/data/datasources/remote_media_source.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/data/services/dio_client.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/utils/hash.dart';
import 'package:path/path.dart' as p;

class RemoteMediaDataSource {
  // ignore: unused_field
  final DioClient _dioClient;
  final Dio _dio;
  final Dio _fileDio;
  final String baseUrl = ApiConfig.baseUrl;

  RemoteMediaDataSource(this._dioClient)
    : _dio = _dioClient.dio,
      _fileDio = _dioClient.fileDio;

  Future<List<MediaResponse>> getMediaList({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/media',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => MediaResponse.fromJson(json)).toList();
      } else {
        throw Exception('获取媒体列表失败: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '获取媒体列表');
    }
  }

  Future<bool> deleteMedia(String uuid) async {
    try {
      final response = await _dio.delete('$baseUrl/media/$uuid');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('删除媒体失败: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '删除媒体');
    }
  }

  Future<bool> restoreMedia(String uuid) async {
    try {
      final response = await _dio.post('$baseUrl/media/$uuid/restore');
      // 成功恢复通常返回 200 OK
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('恢复媒体失败: ${response.data?['message']}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '恢复媒体');
    }
  }

  Future<bool> purgeMedia(String uuid) async {
    try {
      final response = await _dio.delete('$baseUrl/media/$uuid/purge');
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('永久删除媒体失败: ${response.data?['message']}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '永久删除媒体');
    }
  }

  Future<Uint8List> downloadPreviewMedia(String uuid) async {
    final MediaResponse mediaItem;
    try {
      mediaItem = await getMediaDetail(uuid);
    } on DioException catch (e) {
      throw _handleDioError(e, '下载缩略图');
    }

    try {
      final response = await _fileDio.get(
        mediaItem.previewUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return response.data as Uint8List;
      } else {
        throw Exception('下载预览文件失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '下载预览文件');
    }
  }

  Future<Uint8List> downloadThumbnail(String uuid) async {
    final MediaResponse mediaItem;
    try {
      mediaItem = await getMediaDetail(uuid);
    } on DioException catch (e) {
      throw _handleDioError(e, '下载缩略图');
    }

    try {
      final response = await _fileDio.get(
        mediaItem.thumbnailUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return response.data as Uint8List;
      } else {
        throw Exception('下载缩略图失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '下载缩略图');
    }
  }

  Future<String> getThumbnailUrl(String uuid) async {
    try {
      // 我们可以优化这个调用，如果 thumbnail URL 可以直接拼接，就不需要先获取详情
      // 但为了保持与现有逻辑一致，我们先调用 getMediaDetail
      final mediaItem = await getMediaDetail(uuid);
      return mediaItem.thumbnailUrl;
    } on DioException catch (e) {
      throw _handleDioError(e, '获取缩略图URL');
    }
  }

  Future<MediaResponse> getMediaDetail(String uuid) async {
    try {
      final response = await _dio.get('$baseUrl/media/$uuid');

      if (response.statusCode == 200) {
        return MediaResponse.fromJson(response.data['data']);
      } else {
        throw Exception('获取媒体详情失败: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '获取媒体详情');
    }
  }

  Future<CheckHashesResponse> checkHashes(CheckHashesRequest intput) async {
    try {
      final response = await _dio.post('$baseUrl/media/check_hashes');

      if (response.statusCode == 200) {
        return CheckHashesResponse.fromJson(response.data['data']);
      } else {
        throw Exception('检查hash失败: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '检查hash失败');
    }
  }

  Future<MediaChangesResponse> getChanges({DateTime? since}) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (since != null) {
        final sinceStr = '${since.toUtc().toIso8601String().split('.').first}Z';
        queryParameters['since'] = sinceStr;
      }

      print('RemoteMediaSource: 发起增量同步请求，参数: $queryParameters');
      final response = await _dio.get(
        '$baseUrl/media/changes',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        print('RemoteMediaSource: 收到响应数据: $responseData');

        if (responseData == null || responseData['data'] == null) {
          throw Exception('服务器返回了空数据');
        }

        final data = responseData['data'];

        return MediaChangesResponse.fromJson(data);
      } else {
        final message = response.data?['message'] ?? '未知错误';
        throw Exception('获取增量变更失败: $message');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '获取增量变更失败');
    } catch (e) {
      print('RemoteMediaSource: getChanges 发生异常: $e');
      rethrow;
    }
  }

  Future<MediaResponse> uploadFile(File file, MediaType itemType) async {
    try {
      final fileName = p.basename(file.path);
      final String hash = await calculateFileHash(file);
      final Uint8List fileBytes = await file.readAsBytes();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        'item_type': itemType.name,
        'original_filename': fileName,
        'hash': hash,
      });

      final response = await _fileDio.post(
        '$baseUrl/media/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MediaResponse.fromJson(response.data['data']);
      } else {
        throw Exception('上传媒体失败: ${response.data?['message']}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '上传媒体');
    }
  }

  Exception _handleDioError(DioException e, String operation) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'] ?? '服务器错误';

      switch (statusCode) {
        case 400:
          return Exception('$operation失败: 请求参数错误 - $message');
        case 401:
          return Exception('$operation失败: 未授权访问');
        case 403:
          return Exception('$operation失败: 权限不足');
        case 404:
          return Exception('$operation失败: 资源未找到');
        case 410:
          return Exception('$operation失败: 资源已过期');
        case 500:
          return Exception('$operation失败: 服务器内部错误');
        default:
          return Exception('$operation失败: $message');
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('$operation失败: 连接超时，请检查网络');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('$operation失败: 接收数据超时');
    } else if (e.type == DioExceptionType.sendTimeout) {
      return Exception('$operation失败: 发送数据超时');
    } else {
      return Exception('$operation失败: 网络错误 - ${e.message}');
    }
  }
}
