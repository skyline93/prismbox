// lib/core/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'service_locator.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // 生成的扩展方法名
  preferRelativeImports: true, // 使用相对路径
  asExtension: true, // 作为 getIt 的扩展方法生成
)
Future<void> configureDependencies() async => getIt.init();
