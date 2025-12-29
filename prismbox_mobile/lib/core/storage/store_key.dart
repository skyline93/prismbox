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
  lastAutoBackupTriggerTime<DateTime>._(43),

  // 用户设置
  preferRemoteImage<bool>._(100),
  loadPreview<bool>._(101),
  loadOriginal<bool>._(102),

  // 本地同步设置
  dataSourceThreshold<int>._(110), // 数据源切换阈值（数据库资产数量）

  // 应用外观设置
  themeColor<String>._(200), // 主题色（如 "blue", "green", "purple" 等）
  language<String>._(201); // 语言（如 "zh_CN", "en"）

  final int id;
  const StoreKey._(this.id);
}
