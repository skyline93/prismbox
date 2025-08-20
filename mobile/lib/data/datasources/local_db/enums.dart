enum SyncStatus {
  localOnlyNotSelected,
  uploading,
  synced,
  cloudOnly,
  downloading,
  error,
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
