// lib/presentation/pages/backup/backup_management_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/presentation/widgets/backup/upload_task_list.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';
import 'package:prismbox/services/backup/upload_service.dart';

/// 备份管理页面
/// 显示上传任务列表，支持筛选、重试、取消等操作
@RoutePage()
class BackupManagementPage extends ConsumerStatefulWidget {
  const BackupManagementPage({super.key});

  @override
  ConsumerState<BackupManagementPage> createState() =>
      _BackupManagementPageState();
}

class _BackupManagementPageState extends ConsumerState<BackupManagementPage> {
  UploadTaskStatus? _filterStatus;
  UploadTaskType? _filterTaskType;

  @override
  Widget build(BuildContext context) {
    final authServiceAsync = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('备份管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'all') {
                  _filterStatus = null;
                } else {
                  _filterStatus = UploadTaskStatus.values.firstWhere(
                    (e) => e.toString().split('.').last == value,
                  );
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('全部'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('待上传'),
              ),
              const PopupMenuItem(
                value: 'uploading',
                child: Text('上传中'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('已完成'),
              ),
              const PopupMenuItem(
                value: 'failed',
                child: Text('失败'),
              ),
              const PopupMenuItem(
                value: 'permanentlyFailed',
                child: Text('永久失败'),
              ),
            ],
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: authServiceAsync.when(
        data: (authService) => FutureBuilder<String>(
          future: authService.getProfile().then((p) => p.id.toString()),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _BackupManagementContent(
              userId: snapshot.data!,
              filterStatus: _filterStatus,
              filterTaskType: _filterTaskType,
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('加载失败: $error'),
        ),
      ),
    );
  }
}

class _BackupManagementContent extends ConsumerWidget {
  final String userId;
  final UploadTaskStatus? filterStatus;
  final UploadTaskType? filterTaskType;

  const _BackupManagementContent({
    required this.userId,
    this.filterStatus,
    this.filterTaskType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadServiceFuture = ref.watch(uploadServiceProvider.future);

    return FutureBuilder<UploadService>(
      future: uploadServiceFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return UploadTaskList(
          userId: userId,
          uploadService: snapshot.data!,
          filterStatus: filterStatus,
          filterTaskType: filterTaskType,
        );
      },
    );
  }
}

