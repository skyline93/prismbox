// lib/ui/media/widgets/sync_status_icon.dart

import 'package:flutter/material.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';

class SyncStatusIcon extends StatelessWidget {
  final SyncStatus status;

  const SyncStatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SyncStatus.uploading:
        return _buildProgressIcon(Icons.cloud_upload, Colors.blue);
      case SyncStatus.downloading:
        return _buildProgressIcon(Icons.cloud_download, Colors.green);
      case SyncStatus.synced:
        return _buildIconWithBackground(Icons.cloud_done, Colors.white);
      case SyncStatus.cloudOnly:
        return _buildIconWithBackground(Icons.cloud_queue, Colors.white);
      case SyncStatus.uploadFailed:
        return _buildIconWithBackground(
          Icons.cloud_upload,
          Colors.orangeAccent,
        );
      case SyncStatus.downloadFailed:
        return _buildIconWithBackground(
          Icons.cloud_download,
          Colors.orangeAccent,
        );
      case SyncStatus.error:
        return _buildIconWithBackground(Icons.error_outline, Colors.redAccent);
      case SyncStatus.localOnlyNotSelected:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProgressIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconWithBackground(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
