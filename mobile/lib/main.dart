// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/providers.dart';

void main() async {
  // 确保 Flutter 小部件绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 3. 在 runApp 之前，调用并等待本地化数据加载完成
  // 我们需要中文 ('zh_CN') 的数据，所以传入该参数
  await initializeDateFormatting('zh_CN', null);

  // 1. 在 runApp 之前，异步等待 SharedPreferences 实例加载完成
  final sharedPreferences = await SharedPreferences.getInstance();

  // 2. 运行应用，并使用 ProviderScope 的 overrides 功能来注入已完成的实例
  runApp(
    ProviderScope(
      overrides: [
        // 用我们已经获取到的实例来覆盖 provider 的默认行为
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(), // 你的应用根组件
    ),
  );
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
