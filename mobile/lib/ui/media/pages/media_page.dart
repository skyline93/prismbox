// lib/ui/media/pages/media_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/ui/media/widgets/media_bar_top.dart';
import 'package:mobile/ui/media/widgets/media_body.dart';

@RoutePage()
class MediaPage extends HookConsumerWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const MediaAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          final jobManager = ref.read(syncJobManagerProvider);
          await jobManager.createCloudChangesSyncJob();
        },
        child: const MediaBody(),
      ),
    );
  }
}
