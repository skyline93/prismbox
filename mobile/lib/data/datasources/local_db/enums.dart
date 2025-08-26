// lib/data/datasources/local_db/enums.dart

enum SyncStatus {
  localOnlyNotSelected,
  uploading,
  synced,
  cloudOnly,
  downloading,
  error,
  uploadFailed,
  downloadFailed,
}

enum JobType {
  upload,
  deleteCloud,
  downloadOriginal,
  downloadThumbnail,
  syncCloudChanges,
  processCloudCreate,
  processCloudDelete,
}

enum JobStatus { pending, inProgress, failed }

enum NetworkConstraint { any, wifiOnly }

enum AlbumSource { local, remote }
