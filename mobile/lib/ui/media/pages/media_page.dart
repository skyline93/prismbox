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
    // [-] The reference to the viewModel is no longer needed here.
    // final viewModel = ref.read(mediaViewModelProvider.notifier);

    // [-] The entire ref.listen block for cloudSyncErrorProvider is removed.
    // Global sync errors are a thing of the past. Errors are now per-item.

    return Scaffold(
      appBar: const MediaAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          // [+] The new onRefresh behavior.
          // This creates a high-priority job to check for cloud changes.
          // It's a "fire and forget" call. The UI does not wait or block.
          final jobManager = ref.read(syncJobManagerProvider);
          await jobManager.createCloudChangesSyncJob();
        },
        child: const MediaBody(),
      ),
    );
  }
}
