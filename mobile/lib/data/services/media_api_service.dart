// lib/data/services/media_api_service.dart

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/services/dio_client.dart';

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
      uploadedChunks: List<int>.from(json['uploaded_chunks'] ?? []),
    );
  }
}

@lazySingleton
class MediaApiService {
  final DioClient _dioClient;

  MediaApiService(this._dioClient);

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

      if (response.statusCode == 200) {
        return null;
      }

      if (response.statusCode == 201) {
        return InitiateUploadResponse.fromJson(response.data['data']);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Unexpected status code: ${response.statusCode}',
      );
    } on DioException {
      rethrow;
    }
  }

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
