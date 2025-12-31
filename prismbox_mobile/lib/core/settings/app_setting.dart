// lib/core/settings/app_setting.dart

import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';

/// 应用设置枚举
/// 定义所有应用设置及其默认值
enum Setting<T> {
  /// 是否优先使用远程图片
  preferRemoteImage<bool>(StoreKey.preferRemoteImage, false),

  /// 是否加载预览图
  loadPreview<bool>(StoreKey.loadPreview, true),

  /// 是否加载原图
  loadOriginal<bool>(StoreKey.loadOriginal, false),

  /// 数据源切换阈值（数据库资产数量）
  /// 当数据库资产数量大于此值时，使用数据库数据源
  /// 默认值：100
  dataSourceThreshold<int>(StoreKey.dataSourceThreshold, 1),

  /// 主题色
  /// 默认值：blue
  themeColor<String>(StoreKey.themeColor, 'blue'),

  /// 语言
  /// 默认值：zh_CN（中文简体）
  language<String>(StoreKey.language, 'zh_CN'),

  /// 是否启用生物识别解锁加密空间
  /// 默认值：false
  encryptedSpaceBiometricEnabled<bool>(StoreKey.encryptedSpaceBiometricEnabled, false),

  /// 加密空间自动锁定超时时间（分钟）
  /// 默认值：30分钟
  /// 特殊值：0 表示永不自动锁定（仅令牌过期时锁定）
  encryptedSpaceLockTimeoutMinutes<int>(StoreKey.encryptedSpaceLockTimeoutMinutes, 30);

  const Setting(this.storeKey, this.defaultValue);

  final StoreKey<T> storeKey;
  final T defaultValue;
}

/// 应用设置工具类
/// 提供统一的设置访问接口
class AppSetting {
  static final StoreService _store = StoreService();

  /// 获取设置值
  static T get<T>(Setting<T> setting) {
    return _store.get(setting.storeKey, setting.defaultValue);
  }

  /// 设置值
  static Future<void> set<T>(Setting<T> setting, T value) async {
    await _store.put(setting.storeKey, value);
  }

  /// 监听设置变化
  static Stream<T?> watch<T>(Setting<T> setting) {
    return _store.watch(setting.storeKey);
  }
}
