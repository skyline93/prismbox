// lib/providers/post/post_task_provider.dart

import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/services/post/post_task_manager.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';
import 'package:prismbox/providers/post/post_providers.dart';

part 'post_task_provider.g.dart';

/// 帖子任务状态 Provider（按任务 ID）
@riverpod
Future<PostTaskEntityData?> postTask(
  PostTaskRef ref,
  String taskId,
) async {
  final database = await ref.watch(databaseProvider.future);
  return await database.postTaskDao.getTaskById(taskId);
}

/// 帖子任务状态流 Provider（按任务 ID）
/// 监听任务状态变化
@riverpod
Stream<PostTaskStatusUpdate> postTaskStatusStream(
  PostTaskStatusStreamRef ref,
  String taskId,
) async* {
  final postTaskManager = await ref.watch(postTaskManagerProvider.future);
  
  // 先发送当前状态
  final database = await ref.watch(databaseProvider.future);
  final task = await database.postTaskDao.getTaskById(taskId);
  if (task != null) {
    yield PostTaskStatusUpdate(
      taskId: taskId,
      status: task.status,
      progress: task.progress,
      errorMessage: task.errorMessage,
    );
  }

  // 监听状态变化
  yield* postTaskManager.taskStatusStream
      .where((update) => update.taskId == taskId);
}

/// 用户的所有帖子任务列表 Provider
@riverpod
Future<List<PostTaskEntityData>> postTasks(
  PostTasksRef ref,
  String userId,
) async {
  final database = await ref.watch(databaseProvider.future);
  return await database.postTaskDao.getPendingTasksByUserId(userId);
}

/// 失败的帖子任务列表 Provider
@riverpod
Future<List<PostTaskEntityData>> failedPostTasks(
  FailedPostTasksRef ref,
  String userId,
) async {
  final database = await ref.watch(databaseProvider.future);
  return await database.postTaskDao.getFailedTasksByUserId(userId);
}

