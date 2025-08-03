// lib/ui/pages/login_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../auth/notifiers/auth_notifier.dart';
import 'package:mobile/routing/app_router.dart';

@RoutePage()
class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController(
      text: 'admin',
    ); // 预填方便测试
    final passwordController = useTextEditingController(text: '12345678');
    final authState = ref.watch(authNotifierProvider);

    // 监听状态，用于导航和显示错误提示
    ref.listen(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        authenticated: () => {
          context.router.replaceAll([const HomeRoute()]),
        },
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("认证错误: $message"),
              backgroundColor: Colors.red,
            ),
          );
          ref.read(authNotifierProvider.notifier).resetToUnauthenticated();
        },
        orElse: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: '用户名'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '密码'),
            ),
            const SizedBox(height: 32),
            authState.maybeWhen(
              loading: () => const CircularProgressIndicator(),
              orElse: () => ElevatedButton(
                onPressed: () {
                  ref
                      .read(authNotifierProvider.notifier)
                      .login(usernameController.text, passwordController.text);
                },
                child: const Text('登录'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
