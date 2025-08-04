class AppConfig {
  AppConfig._();

  static const ApiConfig api = ApiConfig();
}

class ApiConfig {
  const ApiConfig();

  static const String defaultServerAddr = 'http://127.0.0.1:8080';
  static const String apiVersion = 'v1';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
