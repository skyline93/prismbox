// lib/main.dart
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'app/app.dart'; // 您的应用根组件
import 'presentation/providers/providers.dart'; // 您的providers文件

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FileDownloader().configure(
    globalConfig: [(Config.requestTimeout, const Duration(seconds: 120))],
  );

  // 创建一个Provider容器来预先初始化服务
  final container = ProviderContainer();

  // 初始化管理器，让它开始监听所有后台任务的更新
  container.read(transferManagerProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(), // 您的应用根组件
    ),
  );
}
