// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/services/background_service_manager.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/services/local_media_observer.dart';
import 'package:storage_inspector/storage_inspector.dart';
import 'package:drift_local_storage_inspector/drift_local_storage_inspector.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/local_db/connection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDatabaseIsolate();

  await configureDependencies();
  await initializeDateFormatting('zh_CN', null);

  // 启动本地相册监听
  getIt<LocalMediaObserver>().startObserving();

  await BackgroundServiceManager.initialize();
  await BackgroundServiceManager.registerPeriodicSync();

  // 仅在调试模式下启动 Storage Inspector
  if (kDebugMode) {
    // 1. 创建 Storage Inspector 驱动
    final driver = StorageServerDriver(
      bundleId: 'com.album.bundle.id', // 用于在 IDE 中识别你的应用
      port: 1555,
    );

    final db = getIt<AppDatabase>();

    // 2. 创建 Drift 数据库的服务器实例
    final driftServer = DriftSQLDatabaseServer(
      id: 'album_drift_database', // 服务器的唯一ID
      name: 'Album Drift DB', // 在IDE中显示的名称
      database: db, // 传入你的 Drift 数据库实例
    );

    // 3. 将 Drift 服务器添加到驱动中
    driver.addSQLServer(driftServer);

    // 4. 启动驱动服务
    await driver.start();

    // 你可以在控制台打印端口号，虽然通常不需要，因为 IDE 会自动发现
    print('Storage Inspector server running on port ${driver.port}');
  }

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '媒体管理 App',
      routerConfig: appRouter.config(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}
