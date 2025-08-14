// lib/ui/media/pages/media_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/ui/media/widgets/media_bar_top.dart';
import 'package:mobile/ui/media/widgets/media_body.dart';
import 'package:mobile/ui/media/viewmodels/media_viewmodel.dart';

@RoutePage()
class MediaPage extends HookConsumerWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(mediaViewModelProvider.notifier);

    ref.listen<String?>(cloudSyncErrorProvider, (previous, newError) {
      if (newError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(newError)),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: () => viewModel.syncWithCloud(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    return Scaffold(
      appBar: const MediaAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await viewModel.syncWithCloud();
        },
        child: const MediaBody(),
      ),
    );
  }
}
