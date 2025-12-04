/// Store键定义
/// 定义所有存储在Store中的键及其类型
enum StoreKey<T> {
  // 服务器配置
  serverUrl<String>._(0),
  serverEndpoint<String>._(1),
  accessToken<String>._(2),
  refreshToken<String>._(3),
  currentUser<String>._(4), // JSON字符串

  // SSL配置
  allowSelfSignedSSLCert<bool>._(10),
  sslClientCertData<String>._(11),
  sslClientCertPassword<String>._(12),

  // 自定义请求头
  customHeaders<String>._(20),

  // 设备信息
  deviceId<String>._(30),
  deviceModel<String>._(31),
  deviceType<String>._(32),

  // 备份设置
  autoBackup<bool>._(40),
  backupRequireWifi<bool>._(41),
  backupRequireCharging<bool>._(42),

  // 用户设置
  preferRemoteImage<bool>._(100),
  loadPreview<bool>._(101),
  loadOriginal<bool>._(102);

  final int id;
  const StoreKey._(this.id);
}

