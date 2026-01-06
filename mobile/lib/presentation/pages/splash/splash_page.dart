// lib/presentation/pages/splash/splash_page.dart

import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/providers/auth/auth_state_provider.dart';
import 'package:prismbox/providers/permission/photo_permission_provider.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:logging/logging.dart';

/// 启动页面
/// 检查认证状态并导航到相应页面
@RoutePage()
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  final _log = Logger('SplashPage');
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // 使用 postFrameCallback 确保在第一个 frame 之后检查
    // 这样可以确保 Store 已经完全初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigateFast();
      // 后台预加载数据
      _preloadData();
    });
  }

  /// 快速检查认证状态并导航（参考 immich 的方式）
  /// 直接从 Store 读取 token，不等待 Provider 初始化
  void _checkAndNavigateFast() {
    if (_hasNavigated) return;
    
    try {
      final store = StoreService();
      _log.info('Store initialized: ${store.isInitialized}');
      
      if (!store.isInitialized) {
        // Store 未初始化，等待一下再检查
        _log.warning('Store not initialized, retrying in 100ms');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_hasNavigated) {
            _checkAndNavigateFast();
          }
        });
        return;
      }

      final accessToken = store.tryGet<String>(StoreKey.accessToken);

      _log.info('Token check: accessToken=${accessToken != null && accessToken.isNotEmpty}');

      // 注意：serverUrl 和 serverEndpoint 现在从 app_config.dart 读取，不再存储在 Store 中
      // 所以只需要检查 accessToken 即可
      if (accessToken != null && accessToken.isNotEmpty) {
        // 有 token，立即导航到主页（不等待验证）
        _log.info('✅ Token found. Navigating to home immediately.');
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          // 使用 unawaited 不阻塞，后台验证 token
          unawaited(_verifyAuthInBackground());
          context.router.replaceAll([const TabShellRoute()]);
        }
      } else {
        // 没有 token，导航到登录页
        _log.info('❌ No token found. Navigating to login.');
        _log.info('  accessToken: ${accessToken != null ? "exists (${accessToken.length} chars)" : "null"}');
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          context.router.replaceAll([const LoginRoute()]);
        }
      }
    } catch (e, stackTrace) {
      _log.severe('Error in fast navigation: $e', e, stackTrace);
      // 出错时导航到登录页
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.router.replaceAll([const LoginRoute()]);
      }
    }
  }

  /// 后台验证认证状态（不阻塞导航）
  Future<void> _verifyAuthInBackground() async {
    try {
      // 后台验证 token，如果无效则登出
      final authState = await ref.read(authNotifierProvider.future);
      if (authState is! AuthStateAuthenticated) {
        _log.warning('Token verification failed. Logging out.');
        // Token 无效，导航到登录页
        if (mounted) {
          context.router.replaceAll([const LoginRoute()]);
        }
      }
    } catch (e) {
      _log.warning('Background auth verification failed: $e');
      // 验证失败，但不影响已导航的页面
    }
  }

  /// 预加载权限状态和相关数据
  void _preloadData() {
    // 预加载权限状态
    ref.read(photoPermissionNotifierProvider.future).then((permissionState) {
      // 如果权限已授予，预加载时间线相关数据
      if (permissionState is PhotoPermissionGranted) {
        // 预加载 assetEntityLoader
        unawaited(
          ref.read(assetEntityLoaderProvider.future).then(
            (_) {},
            onError: (_) {},
          ),
        );
        
        // 预加载时间线数据
        unawaited(
          ref.read(timelineSectionsProvider.future).then(
            (_) {},
            onError: (_) {},
          ),
        );
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    // 完全隐藏 SplashPage，让它与原生启动画面无缝衔接
    // 不显示任何加载指示器，让用户感觉直接从原生启动画面进入应用
    return Scaffold(
      backgroundColor: Colors.white, // 与原生启动画面背景色一致
      body: Container(), // 完全空白，不显示任何内容
    );
  }
}
