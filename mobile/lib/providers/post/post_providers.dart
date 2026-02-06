// lib/providers/post/post_providers.dart

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/infrastructure/network/post_api_client.dart';
import 'package:prismbox/providers/infrastructure/api_service_provider.dart';
import 'package:prismbox/services/post/post_service.dart';
import 'package:prismbox/services/post/comment_service.dart';
import 'package:prismbox/services/post/post_task_manager.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart' as backup;

part 'post_providers.g.dart';

final _log = Logger('PostProviders');

/// PostApiClient Provider
@riverpod
PostApiClient postApiClient(PostApiClientRef ref) {
  _log.info('[PostProviders] postApiClient provider building');
  final apiService = ref.watch(apiServiceProvider);
  _log.info('[PostProviders] apiServiceProvider watched, creating PostApiClient');
  return PostApiClient(apiService);
}

/// PostService Provider（基础版本，不包含 PostTaskManager）
@riverpod
PostService postServiceBase(PostServiceBaseRef ref) {
  _log.info('[PostProviders] postServiceBase provider building');
  final apiClient = ref.watch(postApiClientProvider);
  _log.info('[PostProviders] postApiClientProvider watched, creating PostService');
  return PostService(apiClient);
}

/// PostTaskManager Provider
@riverpod
Future<PostTaskManager> postTaskManager(PostTaskManagerRef ref) async {
  _log.info('[PostProviders] postTaskManager provider building');
  final database = await ref.watch(databaseProvider.future);
  final postService = ref.watch(postServiceBaseProvider);
  final uploadService = await ref.watch(backup.uploadServiceProvider.future);
  final uploadOrchestrator = await ref.watch(backup.uploadOrchestratorProvider.future);
  final taskFactory = await ref.watch(backup.taskFactoryProvider.future);
  final apiService = ref.watch(apiServiceProvider);
  _log.info('[PostProviders] Dependencies watched, creating PostTaskManager');
  return PostTaskManager(
    database: database,
    postService: postService,
    uploadService: uploadService,
    uploadOrchestrator: uploadOrchestrator,
    taskFactory: taskFactory,
    apiService: apiService,
  );
}

/// PostService Provider（完整版本，包含 PostTaskManager）
@riverpod
Future<PostService> postService(PostServiceRef ref) async {
  _log.info('[PostProviders] postService provider building');
  final apiClient = ref.watch(postApiClientProvider);
  final postTaskManager = await ref.watch(postTaskManagerProvider.future);
  _log.info('[PostProviders] postApiClientProvider watched, creating PostService');
  return PostService(
    apiClient,
    postTaskManager: postTaskManager,
  );
}

/// CommentService Provider
@riverpod
CommentService commentService(CommentServiceRef ref) {
  _log.info('[PostProviders] commentService provider building');
  final apiClient = ref.watch(postApiClientProvider);
  _log.info('[PostProviders] postApiClientProvider watched, creating CommentService');
  return CommentService(apiClient);
}

