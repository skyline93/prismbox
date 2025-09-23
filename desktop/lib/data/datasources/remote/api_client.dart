import '../../services/dio_client.dart';
import 'models/auth_model.dart';
import 'models/media_model.dart';

class ApiClient {
  final DioClient _dioClient;

  ApiClient(this._dioClient);

  // Auth
  Future<UserLoginSuccessData> login(UserLoginInput data) async {
    final response = await _dioClient.dio.post(
      '/auth/login',
      data: data.toJson(),
    );
    return UserLoginSuccessData.fromJson(response.data['data']);
  }

  // Media
  Future<List<MediaResponse>> getMedias() async {
    final response = await _dioClient.dio.get('/media');
    final List<dynamic> data = response.data['data'];
    return data.map((item) => MediaResponse.fromJson(item)).toList();
  }

  Future<CheckHashesResponse> checkHashes(CheckHashesRequest data) async {
    final response = await _dioClient.dio.post(
      '/media/check_hashes',
      data: data.toJson(),
    );
    return CheckHashesResponse.fromJson(response.data['data']);
  }
}
