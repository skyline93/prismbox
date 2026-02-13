import 'package:flutter/material.dart';
import 'package:prismbox/features/backup/models/asset_upload_status.dart';

/// 媒体查看器控制栏组件
///
/// 包含顶部 AppBar 和底部控制栏。
/// 顶部 AppBar：返回、上传（云图标与缩略图一致）、更多操作
/// 底部控制栏：收藏、信息、编辑等功能按钮
class ViewerControlsBar extends StatelessWidget {
  /// 是否显示控制栏
  final bool showControls;

  /// 切换控制栏显示/隐藏回调
  final VoidCallback onToggleControls;

  /// 返回回调
  final VoidCallback? onBack;

  /// 上传回调（仅本地资源显示，用于上传当前媒体到云端）
  final VoidCallback? onUpload;

  /// 当前资源上传状态（与缩略图云图标一致：未上传/上传中/已上传/失败）
  /// null 视为未上传，仅未上传和失败时可点击
  final AssetUploadStatus? uploadStatus;

  /// 更多操作回调
  final VoidCallback? onMore;

  /// 收藏回调
  final VoidCallback? onFavorite;

  /// 当前资源的收藏状态
  final bool? isFavorite;

  /// 信息回调
  final VoidCallback? onInfo;

  /// 编辑回调
  final VoidCallback? onEdit;

  /// 当前资产是否为 Live Photo（显示「播放 Live 视频」按钮）
  final bool isMotionPhoto;

  /// 当前是否正在播放 Live 关联短视频（按钮图标：播放 / 暂停）
  final bool isPlayingMotionVideo;

  /// 播放/暂停 Live 视频回调
  final VoidCallback? onPlayMotionVideo;

  /// 是否显示下载按钮（仅远程资源可下载）
  final bool showDownloadButton;

  /// 下载回调
  final VoidCallback? onDownload;

  const ViewerControlsBar({
    super.key,
    required this.showControls,
    required this.onToggleControls,
    this.onBack,
    this.onUpload,
    this.uploadStatus,
    this.onMore,
    this.onFavorite,
    this.isFavorite,
    this.onInfo,
    this.onEdit,
    this.isMotionPhoto = false,
    this.isPlayingMotionVideo = false,
    this.onPlayMotionVideo,
    this.showDownloadButton = false,
    this.onDownload,
  });

  /// 与缩略图一致的云图标：未上传
  static Widget _buildNotUploadedIcon() {
    return const Icon(
      Icons.cloud_off_outlined,
      color: Colors.black87,
      size: 22,
    );
  }

  /// 与缩略图一致：上传中（云图标 + 外围转圈）
  static Widget _buildUploadingIcon() {
    return const SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            color: Colors.black87,
            size: 22,
          ),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
              backgroundColor: Color.fromRGBO(0, 0, 0, 0.1),
            ),
          ),
        ],
      ),
    );
  }

  /// 与缩略图一致：已上传
  static Widget _buildUploadedIcon() {
    return const Icon(
      Icons.cloud_done_outlined,
      color: Colors.black87,
      size: 22,
    );
  }

  /// 与缩略图一致：上传失败（红色）
  static Widget _buildFailedIcon() {
    return const Icon(
      Icons.cloud_off_outlined,
      color: Colors.red,
      size: 22,
    );
  }

  Widget _uploadStatusIcon() {
    switch (uploadStatus) {
      case AssetUploadStatus.uploading:
        return _buildUploadingIcon();
      case AssetUploadStatus.uploaded:
        return _buildUploadedIcon();
      case AssetUploadStatus.failed:
        return _buildFailedIcon();
      case AssetUploadStatus.notUploaded:
      case null:
        return _buildNotUploadedIcon();
    }
  }

  /// 仅未上传和上传失败时可点击
  bool get _isUploadButtonEnabled =>
      uploadStatus == null ||
      uploadStatus == AssetUploadStatus.notUploaded ||
      uploadStatus == AssetUploadStatus.failed;

  @override
  Widget build(BuildContext context) {
    if (!showControls) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 顶部 AppBar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: false, // AppBar 需要接收点击事件
            child: AppBar(
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.black87),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack ?? () => Navigator.of(context).pop(),
              ),
              actions: [
                if (isMotionPhoto && onPlayMotionVideo != null)
                  Semantics(
                    label: '播放动态视频',
                    child: IconButton(
                      icon: Icon(
                        isPlayingMotionVideo
                            ? Icons.motion_photos_pause_outlined
                            : Icons.play_circle_outline_rounded,
                        color: Colors.black87,
                      ),
                      onPressed: onPlayMotionVideo,
                    ),
                  ),
                if (showDownloadButton && onDownload != null)
                  Semantics(
                    label: '下载到相册',
                    child: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: onDownload,
                    ),
                  ),
                if (onUpload != null)
                  Semantics(
                    label: uploadStatus == AssetUploadStatus.uploading
                        ? '上传中'
                        : uploadStatus == AssetUploadStatus.uploaded
                            ? '已上传'
                            : uploadStatus == AssetUploadStatus.failed
                                ? '上传失败，点击重试'
                                : '上传',
                    child: IconButton(
                      icon: _uploadStatusIcon(),
                      onPressed: _isUploadButtonEnabled ? onUpload : null,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed:
                      onMore ??
                      () {
                        // TODO: 显示更多选项
                      },
                ),
              ],
            ),
          ),
        ),
        // 底部控制栏
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: false, // 按钮需要接收点击事件
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      isFavorite == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFavorite == true ? Colors.red : Colors.black87,
                    ),
                    onPressed:
                        onFavorite ??
                        () {
                          // TODO: 切换收藏状态
                        },
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.info_outline, color: Colors.black87),
                    onPressed:
                        onInfo ??
                        () {
                          // TODO: 显示信息
                        },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.black87),
                    onPressed:
                        onEdit ??
                        () {
                          // TODO: 编辑媒体
                        },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
