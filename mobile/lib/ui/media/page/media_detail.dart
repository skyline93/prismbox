import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/ui/media/viewmodels/media_state.dart';

class MediaDetailPage extends ConsumerWidget {
  final UnifiedMediaEntity media;

  const MediaDetailPage({super.key, required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaViewModelProvider);
    // final state = ref.watch(mediaDetailViewModelProvider(photo));

    if (mediaState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (mediaState.error != null) {
      return Scaffold(body: Center(child: Text('错误: ${mediaState.error}')));
    }

    return _buildDetailScreen(context, ref, mediaState);

    // return mediaState.when(
    //   loading: () =>
    //       const Scaffold(body: Center(child: CircularProgressIndicator())),
    //   error: (error, stack) =>
    //       Scaffold(body: Center(child: Text('错误: $error'))),
    //   data: (state) => _buildDetailScreen(context, ref, state),
    // );
  }

  Widget _buildDetailScreen(
    BuildContext context,
    WidgetRef ref,
    MediaState state,
  ) {
    final viewModel = ref.read(mediaViewModelProvider(state).notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: viewModel.sharePhoto,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showOptionsMenu(context, viewModel),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => viewModel.toggleZoom(),
        child: Stack(
          children: [
            _buildImageViewer(state),
            if (!state.isZoomed) _buildBottomInfo(context, state),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.toggleFavorite,
        backgroundColor: Colors.red,
        child: Icon(
          state.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildImageViewer(MediaDetailState state) {
    return Center(
      child: Hero(
        tag: 'photo-${state.photo.id}',
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Image.network(
              '${ApiService.baseUrl}/download/${state.photo.id}',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 100,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo(BuildContext context, MediaDetailState state) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.photo.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDateTime(state.photo.createDate),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatFileSize(state.photo.fileSize)} • ${state.photo.width}x${state.photo.height}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (state.photo.type == PhotoType.video) ...[
              const SizedBox(height: 4),
              Text(
                '时长: ${_formatDuration(state.photo.duration)}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, MediaDetailViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download, color: Colors.white),
                title: const Text(
                  '下载原图',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.downloadPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, viewModel);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: const Text('分享', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.sharePhoto();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    MediaDetailViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这张照片吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                viewModel.deletePhoto();
                Navigator.pop(context); // 返回上一页
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final secs = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
  }
}
