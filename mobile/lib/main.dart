// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // 确保 Flutter 绑定已经初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 3. 在 runApp 之前，调用并等待本地化数据加载完成
  // 我们需要中文 ('zh_CN') 的数据，所以传入该参数
  await initializeDateFormatting('zh_CN', null);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从 Provider 获取 router 实例
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
