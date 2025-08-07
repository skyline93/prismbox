import 'package:dio/dio.dart';
import 'package:mobile/data/services/dio_client.dart';
import 'package:mobile/config/app_config.dart';

enum ServerConnectionState {
  checking, // 正在检查
  needsConfig, // 需要配置
  readyToLogin, // 准备登录
}

class ServerCheckService {
  final Dio _dio;
  final baseUrl = DioClient.getBaseUrl();

  ServerCheckService(this._dio);

  Future<bool> ping() async {
    try {
      final response = await _dio.get('${ApiConfig.defaultServerAddr}/ping');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<ServerConnectionState> getCurrentState() async {
    bool isConnect = await ping();

    if (isConnect) {
      return ServerConnectionState.readyToLogin;
    }

    return ServerConnectionState.needsConfig;
  }
}
