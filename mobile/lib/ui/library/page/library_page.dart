import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/routing/app_router.dart';

@RoutePage()
class LibraryPage extends HookConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          Container(
            decoration: BoxDecoration(
              // color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('服务器设置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.router.push(const ServerConfigRoute());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
