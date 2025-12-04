/// OpenAPI客户端包装器
/// 用于集成生成的OpenAPI客户端到ApiService中
///
/// 注意：此文件需要在生成OpenAPI客户端后手动更新
/// 或者可以通过脚本自动生成

// TODO: 取消注释以下导入，在生成OpenAPI客户端后
// import 'package:prismbox/infrastructure/api/generated/api.dart';
// import 'package:prismbox/infrastructure/api/api_service.dart';

/// OpenAPI客户端包装器
/// 提供类型安全的API调用接口
class OpenApiClientWrapper {
  // TODO: 在生成OpenAPI客户端后，取消注释并实现以下属性
  // late final AuthApi authApi;
  // late final MediaApi mediaApi;
  // late final AlbumApi albumApi;
  // late final GroupApi groupApi;
  // late final ShareApi shareApi;
  // late final ServerApi serverApi;

  final String basePath;

  OpenApiClientWrapper(this.basePath) {
    // TODO: 在生成OpenAPI客户端后，取消注释并实现初始化
    // final apiClient = ApiClient(basePath: basePath);
    // authApi = AuthApi(apiClient);
    // mediaApi = MediaApi(apiClient);
    // albumApi = AlbumApi(apiClient);
    // groupApi = GroupApi(apiClient);
    // shareApi = ShareApi(apiClient);
    // serverApi = ServerApi(apiClient);
  }

  /// 设置认证
  void setAuthentication(String token) {
    // TODO: 在生成OpenAPI客户端后实现
    // final apiClient = ApiClient(basePath: basePath);
    // apiClient.setApiKey('x-immich-user-token', token);
  }
}

