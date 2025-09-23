// lib/services/transfer/upload_service.dart
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/logger.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/services/secure_storage_service.dart';
import '../../state/transfer_state.dart';

class UploadService {
  final MediaRepository _mediaRepository;
  final SecureStorageService _secureStorage;
  final String _apiBaseUrl;
  final TransferStateNotifier _transferStateNotifier;

  UploadService({
    required MediaRepository mediaRepository,
    required SecureStorageService secureStorage,
    required String apiBaseUrl,
    required TransferStateNotifier transferStateNotifier,
  }) : _mediaRepository = mediaRepository,
       _secureStorage = secureStorage,
       _apiBaseUrl = apiBaseUrl,
       _transferStateNotifier = transferStateNotifier;

  Future<void> startUploads(List<File> files) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      logger.w("Cannot upload, user is not logged in.");
      return;
    }

    // --- Step 1: Calculate hashes and filter out existing files ---
    final Map<String, File> hashToFileMap = {};
    for (final file in files) {
      // For large files, consider using file.openRead() to avoid loading everything into memory
      final hash = await compute(sha256.convert, await file.readAsBytes());
      hashToFileMap[hash.toString()] = file;
    }

    final existingHashes = await _mediaRepository.checkExistingHashes(
      hashToFileMap.keys.toList(),
    );

    final newHashes = hashToFileMap.keys.where(
      (h) => !existingHashes.contains(h),
    );
    if (newHashes.isEmpty) {
      logger.i("All selected files already exist on the server.");
      return;
    }

    // --- Step 2: Create a list of UploadTasks using UploadTask.fromFile ---
    final tasks = <UploadTask>[];
    for (final hash in newHashes) {
      final file = hashToFileMap[hash]!;
      final filename = p.basename(file.path);
      final mimeType = lookupMimeType(file.path);
      final itemType = (mimeType?.startsWith('video') ?? false)
          ? 'VIDEO'
          : 'IMAGE';

      // MODIFIED: Using UploadTask.fromFile to create a multipart/form-data request
      final task = UploadTask.fromFile(
        file: file, // The File object itself
        url: '$_apiBaseUrl/media/upload-stream',
        fileField: 'file', // The name of the field for the file data
        fields: {
          'hash': hash,
          'item_type': itemType,
          'original_filename': filename,
        },
        headers: {'Authorization': 'Bearer $accessToken'},
        group: 'uploads',
        displayName: filename, // Name used for notifications
      );
      tasks.add(task);
    }

    // --- Step 3: Enqueue all new tasks and update the UI state ---
    if (tasks.isNotEmpty) {
      await FileDownloader().enqueueAll(tasks);
      _transferStateNotifier.addUploadTasks(tasks);
    }
  }

  void handleUploadStatusUpdate(Task task, TaskStatus status) {
    _transferStateNotifier.processStatusUpdate(task, status);
    logger.i("Upload Task ${task.taskId} finished with status: $status");
  }

  void handleUploadProgressUpdate(Task task, double progress) {
    _transferStateNotifier.updateProgress(task, progress);
  }
}
