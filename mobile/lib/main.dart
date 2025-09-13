// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:storage_inspector/storage_inspector.dart';
import 'package:drift_local_storage_inspector/drift_local_storage_inspector.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/local_db/connection.dart';
import 'package:mobile/services/transfer/transfer_manager.dart';
import 'package:mobile/features/sync/coordinator/media_sync_service_proxy.dart';
import 'package:mobile/constants/settings_keys.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobile/features/sync/worker/sync_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      // ignore: avoid_print
      print('ERROR: ${record.error}, StackTrace: ${record.stackTrace}');
    }
  });

  await initializeDatabaseIsolate();

  await configureDependencies();
  await initializeDateFormatting('zh_CN', null);

  await getIt<TransferManager>().initialize();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode, // 在 debug 模式下启用日志，非常有用
  );

  // getIt<LocalMediaObserver>().startObserving();

  final syncService = getIt<MediaSyncServiceProxy>();
  await syncService.start();

  final userSettingDao = getIt<AppDatabase>().userSettingDao;
  final isInitialSyncComplete =
      await userSettingDao.getSetting(
        SettingKeys.initialReconciliationComplete,
      ) ==
      'true';
  if (!isInitialSyncComplete) {
    Logger.root.info(
      'Initial full sync has not been completed. Triggering now...',
    );
    syncService.triggerFullSync();
  } else {
    Logger.root.info(
      'Initial full sync already completed. Skipping automatic trigger on startup.',
    );
    // 后续同步将由 WorkManager 周期性触发，或用户手动触发
  }

  // await BackgroundServiceManager.initialize();
  // await BackgroundServiceManager.registerPeriodicSync();

  if (kDebugMode) {
    final driver = StorageServerDriver(
      bundleId: 'com.album.bundle.id',
      port: 1555,
    );

    final db = getIt<AppDatabase>();

    final driftServer = DriftSQLDatabaseServer(
      id: 'album_drift_database',
      name: 'Album Drift DB',
      database: db,
    );

    driver.addSQLServer(driftServer);

    await driver.start();
    // ignore: avoid_print
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
