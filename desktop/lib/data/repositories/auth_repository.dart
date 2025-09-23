import '../datasources/remote/api_client.dart';
import '../datasources/remote/models/auth_model.dart';
import '../services/secure_storage_service.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storageService;

  AuthRepository(this._apiClient, this._storageService);

  Future<void> login(String username, String password) async {
    final loginData = await _apiClient.login(
      UserLoginInput(username: username, password: password),
    );
    await _storageService.saveTokens(
      accessToken: loginData.accessToken,
      refreshToken: loginData.refreshToken,
    );
  }

  Future<void> logout() async {
    await _storageService.clearTokens();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
