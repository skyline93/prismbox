import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/cache/widgets_binding.dart';
import 'package:prismbox/core/storage/store_repository.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/infrastructure/api/ssl/http_ssl_options.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/data/database/connection.dart';
import 'package:prismbox/services/debug/storage_inspector_service.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart' as backup;
import 'package:prismbox/providers/post/post_providers.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';
import 'package:prismbox/providers/settings/theme_provider.dart';
import 'package:prismbox/providers/settings/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  // 使用自定义 WidgetsFlutterBinding 以启用 CustomImageCache
  // 实现三级缓存分离（ThumbHash/小图/大图），防止大图驱逐小图
  PrismBoxWidgetsBinding();
  
  // 应用 SSL 配置（必须在应用启动时调用）
  // 配置从 AppConfig.ssl 读取，包括是否允许自签名证书等设置
  // 使用 unawaited 因为这是启动时的初始化，不需要等待完成
  unawaited(HttpSSLOptions.apply());
  
  // 配置日志系统
  _setupLogging();

  // 初始化数据库
  await DatabaseConnection.initializeDatabaseIsolate();
  final database = await DatabaseConnection.getInstance();
  
  // 初始化 StoreService（早期初始化，确保全局可用）
  // 这是基础设施服务，需要在应用启动时初始化
  final storeRepository = DriftStoreRepository(database);
  await StoreService().init(storeRepository);
  
  // 在调试模式下启动 Storage Inspector
  if (kDebugMode) {
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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 在 Widget 构建完成后初始化任务管理器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTaskManagers();
    });
  }

  /// 初始化任务管理器并检查未完成的任务
  /// 
  /// **注意**：任务管理器的初始化已经在 Provider 中完成
  /// 这里只需要确保 Provider 被读取，触发初始化，并检查未完成的任务
  Future<void> _initializeTaskManagers() async {
    if (_isInitialized) {
      return;
    }

    try {
      final logger = Logger('MyApp');
      logger.info('Initializing task managers...');

      // 读取 Provider 会触发初始化（在 Provider 中已经完成）
      await ref.read(backup.uploadTaskManagerProvider.future);
      await ref.read(postTaskManagerProvider.future);

      // 检查并恢复未完成的帖子任务
      await _checkAndResumePostTasks(ref);

      _isInitialized = true;
      logger.info('Task managers initialized successfully');
    } catch (e, stackTrace) {
      final logger = Logger('MyApp');
      logger.warning(
        'Failed to initialize task managers: $e',
        e,
        stackTrace,
      );
      // 即使初始化失败，也继续运行应用
    }
  }

  /// 检查并恢复未完成的帖子任务
  Future<void> _checkAndResumePostTasks(WidgetRef ref) async {
    try {
      final logger = Logger('MyApp');
      final database = await ref.read(databaseProvider.future);
      
      // 获取所有用户
      final users = await database.userDao.getAllUsers();
      if (users.isEmpty) {
        return;
      }

      // 恢复每个用户的未完成任务
      final postTaskManager = await ref.read(postTaskManagerProvider.future);
      for (final user in users) {
        await postTaskManager.resumePendingTasks(user.id);
      }
      
      logger.info('Post task recovery completed');
    } catch (e, stackTrace) {
      final logger = Logger('MyApp');
      logger.warning(
        'Failed to check and resume post tasks: $e',
        e,
        stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 通过 Provider 获取 AppRouter 实例
    final router = ref.watch(appRouterProvider);
    // 获取主题数据
    final theme = ref.watch(themeDataProvider);
    // 获取语言设置
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'PrismBox',
      debugShowCheckedModeBanner: false, // 隐藏右上角的 DEBUG 标识
      theme: theme,
      locale: locale,
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router.config(),
    );
  }
}
