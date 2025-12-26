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
  dataSourceThreshold<int>(StoreKey.dataSourceThreshold, 1);

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

