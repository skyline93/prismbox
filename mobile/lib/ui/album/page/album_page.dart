import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

@RoutePage()
class AlbumPage extends HookConsumerWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('所有相册')),
      body: Center(child: Text("相册页面待开发")),
    );
  }
}
