import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// 资料库页面
@RoutePage()
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资料库'),
      ),
      body: const Center(
        child: Text('资料库页面'),
      ),
    );
  }
}

