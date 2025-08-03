import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/models/server_state.dart';
import 'package:mobile/data/services/api_service.dart';

class ServerCheckService {
  final ApiService _apiService;
  ServerCheckService(this._apiService);

  Future<bool> ping() async {
    final baseUrl = await _apiService.getApiBaseUrl();

    try {
      final response = await _apiService.dio.get('$baseUrl/ping');
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

final serverCheckServiceProvider = Provider<ServerCheckService>((ref) {
  return ServerCheckService(ref.read(apiServiceProvider));
});
