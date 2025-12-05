import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// 登录页面
@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
      ),
      body: const Center(
        child: Text('登录页面'),
      ),
    );
  }
}

