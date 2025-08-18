// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/services/background_service_manager.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/services/local_media_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();
  await initializeDateFormatting('zh_CN', null);

  // 启动本地相册监听
  getIt<LocalMediaObserver>().startObserving();

  await BackgroundServiceManager.initialize();
  await BackgroundServiceManager.registerPeriodicSync();

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
