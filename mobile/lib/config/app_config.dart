// lib/config/app_config.dart

import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  AppConfig._();

  static const ApiConfig api = ApiConfig();
}

class ApiConfig {
  const ApiConfig();

  // 默认服务器地址（生产环境使用 HTTPS）
  // 注意：如果后端启用了 HTTPS，请将地址改为 https://
  static const String defaultServerAddr = 'http://47.107.63.140:18080';
  // static const String defaultServerAddr = 'https://api.example.com';  // HTTPS 示例
  // static const String defaultServerAddr = 'http://10.0.2.2';  // Android 模拟器
  // static const String defaultServerAddr = 'http://127.0.0.1';
  // static const String defaultServerAddr = 'http://10.168.1.161';

  // 支持从本地存储读取自定义服务器地址
  static Future<String> getServerAddr() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customAddr = prefs.getString('server_address');
      return customAddr ?? defaultServerAddr;
    } catch (e) {
      // 如果读取失败，使用默认地址
      return defaultServerAddr;
    }
  }

  // 动态获取 baseUrl
  static Future<String> get baseUrl async {
    final serverAddr = await getServerAddr();
    return '$serverAddr/api/v1';
  }

  // 同步获取 baseUrl（用于不需要异步的场景，使用默认地址）
  static const String baseUrlSync = '$defaultServerAddr/api/v1';
}
