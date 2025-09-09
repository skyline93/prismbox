// lib/ui/transfer/pages/transfer_manager_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers/transfer_providers.dart';
import 'package:mobile/ui/transfer/widgets/download_job_item_widget.dart';

@RoutePage()
class TransferManagerPage extends ConsumerWidget {
  const TransferManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadJobsAsync = ref.watch(downloadJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Manager'),
        leading: const BackButton(),
      ),
      body: downloadJobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(child: Text('No download tasks.'));
          }
          // 默认按创建时间倒序排列
          final sortedJobs = List.of(jobs)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.separated(
            padding: const EdgeInsets.all(8.0),
            itemCount: sortedJobs.length,
            itemBuilder: (context, index) {
              return DownloadJobItemWidget(job: sortedJobs[index]);
            },
            separatorBuilder: (context, index) => const SizedBox(height: 8),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading jobs: $err')),
      ),
    );
  }
}
