// lib/ui/transfer/pages/transfer_manager_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/providers/transfer_providers.dart';
import 'package:mobile/ui/transfer/widgets/download_job_item_widget.dart';
import 'package:mobile/ui/transfer/widgets/upload_job_item_widget.dart'; // [+] 新增

@RoutePage()
class TransferManagerPage extends ConsumerWidget {
  const TransferManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadJobsAsync = ref.watch(downloadJobsProvider);
    final uploadJobsAsync = ref.watch(uploadJobsProvider); // [+] 监听上传任务

    return Scaffold(
      appBar: AppBar(title: const Text('传输管理'), leading: const BackButton()),
      body: uploadJobsAsync.when(
        data: (uploadJobs) => downloadJobsAsync.when(
          data: (downloadJobs) {
            // 合并并排序所有任务
            final List<dynamic> allJobs = [...uploadJobs, ...downloadJobs];
            if (allJobs.isEmpty) {
              return const Center(child: Text('没有传输任务'));
            }
            allJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return ListView.separated(
              padding: const EdgeInsets.all(8.0),
              itemCount: allJobs.length,
              itemBuilder: (context, index) {
                final job = allJobs[index];
                if (job is UploadJob) {
                  return UploadJobItemWidget(job: job);
                } else if (job is DownloadJob) {
                  return DownloadJobItemWidget(job: job);
                }
                return const SizedBox.shrink(); // Should not happen
              },
              separatorBuilder: (context, index) => const SizedBox(height: 8),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('加载下载任务失败: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载上传任务失败: $err')),
      ),
    );
  }
}
