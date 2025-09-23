// lib/state/transfer_state.dart
import 'package:background_downloader/background_downloader.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'transfer_state.freezed.dart';

// 您需要运行 build_runner 来生成 freezed 的部分:
// flutter pub run build_runner build --delete-conflicting-outputs

@freezed
class TaskProgress with _$TaskProgress {
  const factory TaskProgress({required Task task, required double progress}) =
      _TaskProgress;
}

@freezed
class TransferState with _$TransferState {
  const factory TransferState({
    @Default([]) List<TaskProgress> uploads,
    @Default([]) List<TaskProgress> downloads,
  }) = _TransferState;
}

class TransferStateNotifier extends StateNotifier<TransferState> {
  TransferStateNotifier() : super(const TransferState());

  void addUploadTasks(List<UploadTask> tasks) {
    final newProgressList = tasks
        .map((t) => TaskProgress(task: t, progress: 0.0))
        .toList();
    state = state.copyWith(uploads: [...state.uploads, ...newProgressList]);
  }

  void addDownloadTasks(List<DownloadTask> tasks) {
    final newProgressList = tasks
        .map((t) => TaskProgress(task: t, progress: 0.0))
        .toList();
    state = state.copyWith(downloads: [...state.downloads, ...newProgressList]);
  }

  void updateProgress(Task task, double progress) {
    final isUpload = task is UploadTask;
    final list = isUpload ? state.uploads : state.downloads;
    final newList = List<TaskProgress>.from(list);
    final index = newList.indexWhere((p) => p.task.taskId == task.taskId);

    if (index != -1) {
      newList[index] = newList[index].copyWith(progress: progress, task: task);
      if (isUpload) {
        state = state.copyWith(uploads: newList);
      } else {
        state = state.copyWith(downloads: newList);
      }
    }
  }

  void processStatusUpdate(Task task, TaskStatus status) {
    if (status.isFinalState) {
      final isUpload = task is UploadTask;
      final list = isUpload ? state.uploads : state.downloads;
      final newList = List<TaskProgress>.from(list)
        ..removeWhere((p) => p.task.taskId == task.taskId);

      if (isUpload) {
        state = state.copyWith(uploads: newList);
      } else {
        state = state.copyWith(downloads: newList);
      }
    }
  }
}
