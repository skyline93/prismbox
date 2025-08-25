class AppConfig {
  AppConfig._();

  static const ApiConfig api = ApiConfig();
}

class ApiConfig {
  const ApiConfig();

  // static const String defaultServerAddr = 'http://47.107.63.140:18080';
  // static const String defaultServerAddr = 'http://10.0.2.2:8080';
  static const String defaultServerAddr = 'http://127.0.0.1:8080';
  static const String apiVersion = 'v1';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
