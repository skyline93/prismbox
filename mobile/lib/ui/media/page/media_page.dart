import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

@RoutePage()
class MediaPage extends HookConsumerWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('所有照片')),
      body: RefreshIndicator(
        child: Center(child: Text("照片页面待开发")),
        onRefresh: () async => {print("下拉刷新")},
      ),
    );
  }
}
