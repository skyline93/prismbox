// 媒体服务类 - 封装媒体相关的API调用
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/data/services/dio_client.dart';

/// 媒体服务类
/// 提供媒体相关的API接口封装
class RemoteMediaDataSource {
  final Dio _dio;
  final downloadDio = Dio();
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
  Future<MediaResponse> uploadMedia({
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
        return MediaResponse.fromJson(response.data['data']);
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
    final MediaResponse mediaItem;
    try {
      mediaItem = await getMediaDetail(uuid);
    } on DioException catch (e) {
      throw _handleDioError(e, '下载缩略图');
    }

    try {
      final response = await downloadDio.get(
        mediaItem.downloadUrl,
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
    final MediaResponse mediaItem;
    try {
      mediaItem = await getMediaDetail(uuid);
    } on DioException catch (e) {
      throw _handleDioError(e, '下载缩略图');
    }

    try {
      final response = await downloadDio.get(
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

  /// 获取缩略图
  ///
  /// [uuid] 媒体文件的UUID
  ///
  /// 返回缩略图二进制数据
  Future<Uint8List> downloadThumbnail(String uuid) async {
    final MediaResponse mediaItem;
    try {
      mediaItem = await getMediaDetail(uuid);
    } on DioException catch (e) {
      throw _handleDioError(e, '下载缩略图');
    }

    try {
      final response = await downloadDio.get(
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

  /// 获取媒体详细信息
  ///
  /// [uuid] 媒体文件的UUID
  ///
  /// 返回媒体详细信息
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
      // 准备查询参数
      final Map<String, dynamic> queryParameters = {};
      if (since != null) {
        // 只保留到秒，去除微秒部分，保证Go后端兼容
        final sinceStr = '${since.toUtc().toIso8601String().split('.').first}Z';
        queryParameters['since'] = sinceStr;
      }

      print('RemoteMediaSource: 发起增量同步请求，参数: $queryParameters');
      final response = await _dio.get(
        '$baseUrl/media/changes',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        // 1. 先检查并打印原始响应数据，帮助调试
        final responseData = response.data;
        print('RemoteMediaSource: 收到响应数据: $responseData');

        if (responseData == null || responseData['data'] == null) {
          throw Exception('服务器返回了空数据');
        }

        // 2. 确保 data 字段存在且是Map类型
        final data = responseData['data'];

        // 3. 使用安全的类型转换创建响应对象
        return MediaChangesResponse.fromJson(data);
      } else {
        final message = response.data?['message'] ?? '未知错误';
        throw Exception('获取增量变更失败: $message');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, '获取增量变更失败');
    } catch (e) {
      // 添加通用错误处理，包含更多上下文信息
      print('RemoteMediaSource: getChanges 发生异常: $e');
      rethrow;
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
