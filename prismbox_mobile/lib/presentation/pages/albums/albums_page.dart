import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// 相册页面
@RoutePage()
class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('相册'),
      ),
      body: const Center(
        child: Text('相册页面'),
      ),
    );
  }
}

