// lib/data/services/media_api_service.dart

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/services/dio_client.dart';

// 定义初始化上传API的响应模型
class InitiateUploadResponse {
  final String uploadId;
  final int chunkSize;
  final List<int> uploadedChunks;

  InitiateUploadResponse({
    required this.uploadId,
    required this.chunkSize,
    required this.uploadedChunks,
  });

  factory InitiateUploadResponse.fromJson(Map<String, dynamic> json) {
    return InitiateUploadResponse(
      uploadId: json['upload_id'],
      chunkSize: json['chunk_size'],
      uploadedChunks: List<int>.from(json['uploaded_chunks']??[]),
    );
  }
}

@lazySingleton
class MediaApiService {
  final DioClient _dioClient;

  MediaApiService(this._dioClient);

  /// 1. 初始化分片上传
  /// 返回 null 代表秒传成功, 否则返回包含 uploadId 的响应对象
  Future<InitiateUploadResponse?> initiateUpload({
    required String originalFilename,
    required String hash,
    required int totalSize,
    required String itemType,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/media/upload/initiate',
        data: {
          "original_filename": originalFilename,
          "hash": hash,
          "total_size": totalSize,
          "item_type": itemType,
        },
      );

      // 200 OK: 秒传成功，服务端直接返回了 MediaResponse，我们不需要进一步操作
      if (response.statusCode == 200) {
        return null;
      }

      // 201 Created: 需要进行分片上传
      if (response.statusCode == 201) {
        return InitiateUploadResponse.fromJson(response.data['data']);
      }

      // 其他意外状态码
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Unexpected status code: ${response.statusCode}',
      );
    } on DioException {
      // 直接重新抛出，让上层 TransferService 处理
      rethrow;
    }
  }

  /// 2. 通知服务端合并分片
  Future<void> completeUpload({
    required String uploadId,
    required String originalFilename,
    required String hash,
    required String itemType,
  }) async {
    try {
      await _dioClient.dio.post(
        '/media/upload/complete',
        data: {
          "upload_id": uploadId,
          "original_filename": originalFilename,
          "hash": hash,
          "item_type": itemType,
        },
      );
    } on DioException {
      rethrow;
    }
  }
}
