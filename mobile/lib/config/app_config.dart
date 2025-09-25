// lib/config/app_config.dart

class AppConfig {
  AppConfig._();

  static const ApiConfig api = ApiConfig();
}

class ApiConfig {
  const ApiConfig();

  static const String defaultServerAddr = 'http://47.107.63.140:18080';
  // static const String defaultServerAddr = 'http://10.0.2.2:8080';
  // static const String defaultServerAddr = 'http://127.0.0.1:8080';
  // static const String defaultServerAddr = 'http://10.168.1.161:8080';
}
