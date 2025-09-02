import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class RegisterPage extends HookWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usernameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();

    // 为两个密码框分别创建可见性状态
    final isPasswordVisible = useState(false);
    final isConfirmPasswordVisible = useState(false);

    // 统一的蓝色主题色
    const Color primaryBlue = Color(0xFF0095F6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          // 使用 Stack 来放置返回按钮
          children: [
            // 主要内容
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo (与登录页保持一致)
                      const FlutterLogo(size: 80),
                      const SizedBox(height: 48),

                      // 用户名称输入框
                      TextFormField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          hintText: '用户名称',
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
                      ),
                      const SizedBox(height: 16),

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
                              isPasswordVisible.value =
                                  !isPasswordVisible.value;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 确认密码输入框
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !isConfirmPasswordVisible.value,
                        decoration: InputDecoration(
                          hintText: '确认密码',
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
                              isConfirmPasswordVisible.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              isConfirmPasswordVisible.value =
                                  !isConfirmPasswordVisible.value;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 注册按钮
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // 注册逻辑
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            '注册',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // 底部返回登录链接
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '已有账号?',
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () {
                              context.router.pop();
                            },
                            child: const Text(
                              '返回登录',
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
            // 返回按钮 (放在 Stack 的顶层)
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black54,
                ),
                onPressed: () {
                  context.router.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
