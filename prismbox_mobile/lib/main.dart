import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/infrastructure/api/ssl/http_ssl_options.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/data/database/connection.dart';
import 'package:prismbox/services/debug/storage_inspector_service.dart';

void main() async {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 应用 SSL 配置（必须在应用启动时调用）
  // 配置从 AppConfig.ssl 读取，包括是否允许自签名证书等设置
  // 使用 unawaited 因为这是启动时的初始化，不需要等待完成
  unawaited(HttpSSLOptions.apply());
  
  // 配置日志系统
  _setupLogging();

  // 初始化数据库
  await DatabaseConnection.initializeDatabaseIsolate();
  
  // 在调试模式下启动 Storage Inspector
  if (kDebugMode) {
    final database = await DatabaseConnection.getInstance();
    unawaited(StorageInspectorService.initialize(database));
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// 配置日志系统
void _setupLogging() {
  // 在调试模式下，设置日志级别为 ALL，显示所有日志
  // 在发布模式下，可以设置为 INFO 或更高级别
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;

  // 配置日志输出处理器
  Logger.root.onRecord.listen((record) {
    // 格式化日志输出
    final level = record.level.name.padRight(7);
    final time = record.time.toString().substring(11, 23); // 只显示时分秒
    final logger = record.loggerName;
    final message = record.message;

    // 输出基本日志信息
    debugPrint('[$level] $time [$logger] $message');

    // 如果有错误信息，输出错误详情
    if (record.error != null) {
      debugPrint('  ERROR: ${record.error}');
    }

    // 如果有堆栈跟踪，输出堆栈信息
    if (record.stackTrace != null) {
      debugPrint('  STACK: ${record.stackTrace}');
    }
  });

  // 输出日志配置信息
  if (kDebugMode) {
    debugPrint('日志系统已初始化 - 级别: ${Logger.root.level.name}');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 通过 Provider 获取 AppRouter 实例
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PrismBox',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router.config(),
    );
  }
}
