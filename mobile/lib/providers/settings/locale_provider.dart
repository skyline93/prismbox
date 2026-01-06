// lib/providers/settings/locale_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/core/settings/app_setting.dart';

/// 语言 Provider
/// 监听语言设置变化
final languageProvider = StreamProvider<String>((ref) {
  return AppSetting.watch(Setting.language)
      .map((value) => value ?? 'zh_CN');
});

/// 当前语言 Provider
/// 获取当前语言，如果未设置则返回默认值
/// 使用 StreamProvider 来响应式更新
final currentLanguageProvider = StreamProvider<String>((ref) {
  return AppSetting.watch(Setting.language)
      .map((value) => value ?? 'zh_CN');
});

/// Locale Provider
/// 根据语言设置生成 Locale
final localeProvider = Provider<Locale?>((ref) {
  // 监听 StreamProvider 的变化
  final languageAsync = ref.watch(currentLanguageProvider);
  
  // 获取当前值，如果还在加载则使用默认值
  final language = languageAsync.value ?? 'zh_CN';
  return _getLocaleFromString(language);
});

/// 从字符串获取 Locale
Locale? _getLocaleFromString(String language) {
  switch (language) {
    case 'zh_CN':
      return const Locale('zh', 'CN');
    case 'en':
      return const Locale('en', 'US');
    default:
      return const Locale('zh', 'CN');
  }
}

