import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// 权限引导页面
@RoutePage()
class PermissionPage extends StatelessWidget {
  const PermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('权限设置'),
      ),
      body: const Center(
        child: Text('权限引导页面'),
      ),
    );
  }
}

