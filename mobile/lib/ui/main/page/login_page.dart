// lib/ui/main/page/login_page.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

@RoutePage()
class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 创建一个 GlobalKey 用于表单
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isPasswordVisible = useState(false);
    final authState = ref.watch(authNotifierProvider);

    const Color primaryBlue = Color(0xFF0095F6);

    ref.listen(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        authenticated: () => {
          context.router.replaceAll([const NavigationRoute()]),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // 2. 将表单内容包裹在 Form Widget 中
            child: Form(
              key: formKey, // 3. 关联 GlobalKey
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 建议替换成你自己的 App Logo
                    const FlutterLogo(size: 80),
                    const SizedBox(height: 48),

                    // 邮箱输入框
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: '邮箱地址',
                        fillColor: Colors.grey[200],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 20.0,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      // 4. 当用户与输入框交互时自动验证
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      // 5. 添加验证器逻辑
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入您的邮箱地址';
                        }
                        // 使用正则表达式进行邮箱格式验证
                        final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return '请输入有效的邮箱地址';
                        }
                        return null; // 返回 null 表示验证通过
                      },
                    ),
                    const SizedBox(height: 16),

                    // 密码输入框
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible.value,
                      decoration: InputDecoration(
                        hintText: '密码',
                        fillColor: Colors.grey[200],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 20.0,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            isPasswordVisible.value = !isPasswordVisible.value;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 忘记密码
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // 忘记密码逻辑
                        },
                        child: const Text(
                          '忘记密码?',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    authState.maybeWhen(
                      loading: () => const CircularProgressIndicator(),
                      orElse: () => Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                // 6. 在执行登录前先验证表单
                                if (formKey.currentState!.validate()) {
                                  ref
                                      .read(authNotifierProvider.notifier)
                                      .login(
                                        emailController.text,
                                        passwordController.text,
                                      );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: const StadiumBorder(),
                              ),
                              child: const Text(
                                '登录',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (Platform.isIOS || Platform.isMacOS) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: SignInWithAppleButton(
                                text: "使用 Apple 登录",
                                onPressed: () {
                                  ref
                                      .read(authNotifierProvider.notifier)
                                      .loginWithApple();
                                },
                                style: SignInWithAppleButtonStyle.black,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(50),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // 底部注册链接
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '还没有账号?',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () {
                            context.router.push(const RegisterRoute());
                          },
                          child: const Text(
                            '注册新账号',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
