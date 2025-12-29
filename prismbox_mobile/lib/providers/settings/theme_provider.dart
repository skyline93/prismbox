// lib/providers/settings/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/core/settings/app_setting.dart';

/// 主题色 Provider
/// 监听主题色设置变化
final themeColorProvider = StreamProvider<String>((ref) {
  return AppSetting.watch(Setting.themeColor)
      .map((value) => value ?? 'blue');
});

/// 当前主题色 Provider
/// 获取当前主题色，如果未设置则返回默认值
/// 使用 StreamProvider 来响应式更新
final currentThemeColorProvider = StreamProvider<String>((ref) {
  return AppSetting.watch(Setting.themeColor)
      .map((value) => value ?? 'blue');
});

/// 主题数据 Provider
/// 根据主题色生成 ThemeData
final themeDataProvider = Provider<ThemeData>((ref) {
  // 监听 StreamProvider 的变化
  final themeColorAsync = ref.watch(currentThemeColorProvider);
  
  // 获取当前值，如果还在加载则使用默认值
  final themeColor = themeColorAsync.value ?? 'blue';
  final color = _getColorFromString(themeColor);
  
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: color,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );
});

/// 从字符串获取颜色
Color _getColorFromString(String colorString) {
  switch (colorString) {
    case 'blue':
      return Colors.blue;
    case 'green':
      return Colors.green;
    case 'purple':
      return Colors.purple;
    case 'orange':
      return Colors.orange;
    case 'red':
      return Colors.red;
    case 'pink':
      return Colors.pink;
    case 'teal':
      return Colors.teal;
    case 'indigo':
      return Colors.indigo;
    default:
      return Colors.blue;
  }
}

