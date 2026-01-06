import 'package:flutter/material.dart';

/// 媒体查看器控制栏组件
///
/// 包含顶部 AppBar 和底部控制栏。
/// 顶部 AppBar：返回、分享、更多操作
/// 底部控制栏：收藏、信息、编辑等功能按钮
class ViewerControlsBar extends StatelessWidget {
  /// 是否显示控制栏
  final bool showControls;

  /// 切换控制栏显示/隐藏回调
  final VoidCallback onToggleControls;

  /// 返回回调
  final VoidCallback? onBack;

  /// 分享回调
  final VoidCallback? onShare;

  /// 更多操作回调
  final VoidCallback? onMore;

  /// 收藏回调
  final VoidCallback? onFavorite;

  /// 信息回调
  final VoidCallback? onInfo;

  /// 编辑回调
  final VoidCallback? onEdit;

  const ViewerControlsBar({
    super.key,
    required this.showControls,
    required this.onToggleControls,
    this.onBack,
    this.onShare,
    this.onMore,
    this.onFavorite,
    this.onInfo,
    this.onEdit,
  });

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
          child: AppBar(
            backgroundColor: Colors.black.withOpacity(0.5),
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: onShare ?? () {
                  // TODO: 分享媒体
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onMore ?? () {
                  // TODO: 显示更多选项
                },
              ),
            ],
          ),
        ),
        // 底部控制栏
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: onFavorite ?? () {
                    // TODO: 切换收藏状态
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: onInfo ?? () {
                    // TODO: 显示信息
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: onEdit ?? () {
                    // TODO: 编辑媒体
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

