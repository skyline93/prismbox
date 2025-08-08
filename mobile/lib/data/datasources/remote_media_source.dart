// 媒体服务类 - 封装媒体相关的API调用
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/data/services/dio_client.dart';

/// 媒体服务类
/// 提供媒体相关的API接口封装
class RemoteMediaDataSource {
  final Dio _dio;
  final String baseUrl = DioClient.getBaseUrl();

  RemoteMediaDataSource(this._dio);

  /// 获取当前用户的媒体列表（分页）
  ///
  /// [page] 页码，默认为1
  /// [limit] 每页数量，默认为100
  ///
  /// 返回媒体列表响应数据
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

  /// 上传单个媒体文件
  ///
  /// [file] 媒体文件二进制数据
  /// [hash] 文件的SHA256哈希值
  /// [itemType] 媒体类型（图片或视频）
  /// [originalFilename] 原始文件名（可选）
  ///
  /// 返回上传后的媒体详细信息
  Future<MediaDetail> uploadMedia({
    required Uint8List file,
    required String hash,
    required MediaType itemType,
    String? originalFilename,
  }) async {
    try {
      // 创建FormData
      final formData = FormData();

      // 添加文件
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            file,
            filename:
                originalFilename ??
                'upload_${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      );

      // 添加其他字段
      formData.fields.addAll([
        MapEntry('hash', hash),
        MapEntry('item_type', itemType == MediaType.image ? 'IMAGE' : 'VIDEO'),
        if (originalFilename != null)
          MapEntry('original_filename', originalFilename),
      ]);

      final response = await _dio.post(
        '$baseUrl/media/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        return MediaDetail.fromJson(response.data['data']);
      } else {
        throw Exception('上传媒体失败: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '上传媒体');
    }
  }

  /// 删除指定的媒体文件
  ///
  /// [uuid] 媒体文件的UUID
  ///
  /// 返回删除成功或失败
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

  /// 下载原始媒体文件
  ///
  /// [uuid] 媒体文件的UUID
  ///
  /// 返回原始文件二进制数据
  Future<Uint8List> downloadOriginalMedia(String uuid) async {
    try {
      final response = await _dio.get(
        '$baseUrl/media/$uuid/download/original',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return response.data as Uint8List;
      } else {
        throw Exception('下载原始文件失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '下载原始文件');
    }
  }

  /// 获取预览文件（图片或视频预览）
  ///
  /// [uuid] 媒体文件的UUID
  ///
  /// 返回预览文件二进制数据
  Future<Uint8List> downloadPreviewMedia(String uuid) async {
    try {
      final response = await _dio.get(
        '$baseUrl/media/$uuid/download/preview',
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

  /// 获取缩略图
  ///
  /// [uuid] 媒体文件的UUID
  ///
  /// 返回缩略图二进制数据
  Future<Uint8List> downloadThumbnail(String uuid) async {
    try {
      final response = await _dio.get(
        '$baseUrl/media/$uuid/download/thumbnail',
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

  /// 获取媒体详细信息
  ///
  /// [uuid] 媒体文件的UUID
  ///
  /// 返回媒体详细信息
  Future<MediaDetail> getMediaDetail(String uuid) async {
    try {
      final response = await _dio.get('$baseUrl/media/$uuid');

      if (response.statusCode == 200) {
        return MediaDetail.fromJson(response.data['data']);
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

  Future<MediaChangesResponse> getChanges() async {
    try {
      final response = await _dio.get('$baseUrl/media/changes', );

      if (response.statusCode == 200) {
        return MediaChangesResponse.fromJson(response.data['data']);
      } else {
        throw Exception('获取增量变更失败: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '获取增量变更失败');
    }
  }

  /// 处理Dio异常
  ///
  /// [e] Dio异常对象
  /// [operation] 操作描述
  ///
  /// 返回处理后的异常信息
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
