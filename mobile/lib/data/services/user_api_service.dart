// lib/data/services/user_api_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart';

@lazySingleton
class UserApiService {
  final Dio _dio;

  UserApiService(this._dio);

  Future<Response> getMe() {
    return _dio.get('/auth/profile');
  }

  Future<Response> uploadAvatar(File imageFile) async {
    String fileName = basename(imageFile.path);

    FormData formData = FormData.fromMap({
      "avatar": await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
    });

    return _dio.post(
      '/auth/avatar',
      data: formData,
      // (可选) 如果上传大文件，可以监听上传进度
      // onSendProgress: (int sent, int total) {
      //   print('$sent/$total');
      // },
    );
  }
}
