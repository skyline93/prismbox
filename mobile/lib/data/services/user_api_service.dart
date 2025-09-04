// lib/data/services/user_api_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart';

@lazySingleton
class UserApiService {
  final Dio _dio;

  UserApiService(this._dio);

  /// [后端支持] 定义获取当前登录用户信息的接口
  Future<Response> getMe() {
    return _dio.get('/auth/profile');
  }

  /// [新增] 上传用户头像的接口
  /// 它接收一个 File 对象，并将其作为 multipart/form-data 发送
  Future<Response> uploadAvatar(File imageFile) async {
    // 1. 获取文件名
    String fileName = basename(imageFile.path);

    // 2. 创建 FormData 对象
    // "avatar" 这个 key 必须与您 Go 后端代码中 c.FormFile("avatar") 的参数完全一致
    FormData formData = FormData.fromMap({
      "avatar": await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
    });

    // 3. 发送 POST 请求到 /auth/avatar
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
