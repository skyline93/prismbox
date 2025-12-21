// lib/presentation/widgets/media/selectable_media_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/backup/models/asset_upload_status.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/presentation/widgets/media/media_image_widget.dart';
import 'package:prismbox/services/backup/providers/asset_upload_status_provider.dart';
import 'package:prismbox/utils/color_extensions.dart';

/// 可选择的媒体项组件
/// 支持显示选中状态（向内缩进效果 + 选中标记）
/// 支持拖动选择（在选择模式下，拖动经过的项会被选中）
class SelectableMediaItem extends StatefulWidget {
  final BaseAsset asset;
  final bool isSelected;
  final bool selectionActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? serverUrl;
  final AssetEntityLoader? assetEntityLoader;
  

  const SelectableMediaItem({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.selectionActive,
    this.onTap,
    this.onLongPress,
    this.serverUrl,
    this.assetEntityLoader,
  });

  @override
  State<SelectableMediaItem> createState() => _SelectableMediaItemState();
}

class _SelectableMediaItemState extends State<SelectableMediaItem> {
  @override
  Widget build(BuildContext context) {
    // 计算选中时的容器颜色（与 Immich 保持一致）
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final assetContainerColor = isDarkTheme
        ? primaryColor.darken(amount: 0.6)
        : primaryColor.lighten(amount: 0.8);

    // 性能优化：使用 RepaintBoundary 隔离绘制，避免局部重绘影响整树
    return RepaintBoundary(
      child: GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 使用 AnimatedContainer 实现选中时的边框效果（向内缩进）
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.decelerate,
            decoration: BoxDecoration(
              color: widget.selectionActive && widget.isSelected ? assetContainerColor : Colors.transparent,
              border: widget.selectionActive && widget.isSelected
                  ? Border.all(
                      color: assetContainerColor,
                      width: 8,
                    )
                  : const Border(),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 媒体图片（选中时添加圆角）
                _ImageContent(
                  asset: widget.asset,
                  isSelected: widget.selectionActive && widget.isSelected,
                  serverUrl: widget.serverUrl,
                  assetEntityLoader: widget.assetEntityLoader,
                  assetContainerColor: assetContainerColor,
                ),
              ],
            ),
          ),

          // 选中标记（左上角）
          if (widget.selectionActive)
            widget.isSelected
                ? const Padding(
                    padding: EdgeInsets.all(3.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: _SelectedIcon(),
                    ),
                  )
                : const Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(
                      Icons.circle_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
          
          // 上传状态图标（右上角）
          _UploadStatusIcon(asset: widget.asset),
        ],
      ),
      ),
    );
  }
}

/// 图片内容（选中时添加圆角和背景色）
class _ImageContent extends StatelessWidget {
  final BaseAsset asset;
  final bool isSelected;
  final String? serverUrl;
  final AssetEntityLoader? assetEntityLoader;
  final Color assetContainerColor;

  const _ImageContent({
    required this.asset,
    required this.isSelected,
    this.serverUrl,
    this.assetEntityLoader,
    required this.assetContainerColor,
  });

  @override
  Widget build(BuildContext context) {
    final image = MediaImageWidget(
      asset: asset,
      isThumbnail: true,
      serverUrl: serverUrl,
      assetEntityLoader: assetEntityLoader,
    );

    if (!isSelected) {
      return image;
    }

    // 选中时添加圆角和背景色，实现向内缩进的效果
    // 性能优化：使用 Container 的 decoration 替代 ClipRRect，避免 saveLayer 开销
    // 注意：如果图片需要溢出裁剪，可以考虑预处理图片或使用其他方案
    return Container(
      decoration: BoxDecoration(
        color: assetContainerColor,
        borderRadius: const BorderRadius.all(Radius.circular(15.0)),
      ),
      child: image,
    );
  }
}

/// 选中图标
class _SelectedIcon extends StatelessWidget {
  const _SelectedIcon();

  @override
  Widget build(BuildContext context) {
    // 使用谷歌蓝作为选中图标的颜色
    const googleBlue = Color(0xFF4285F4); // 谷歌蓝

    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Icon(
        Icons.check_circle_rounded,
        color: googleBlue,
        size: 16,
      ),
    );
  }
}

/// 上传状态图标组件
/// 根据资产上传状态显示不同的图标：
/// - 仅存在于服务端：云朵图标（cloud_outlined，中间没有勾）
/// - 未上传：云朵关闭图标（cloud_off_outlined，白色）
/// - 上传中：云朵上传图标（cloud_upload_outlined），带旋转动画
/// - 已上传：云朵完成图标（cloud_done_outlined）
/// - 上传失败：云朵关闭图标（cloud_off_outlined，红色）
class _UploadStatusIcon extends ConsumerWidget {
  final BaseAsset asset;
  
  const _UploadStatusIcon({required this.asset});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 如果仅存在于服务端，直接显示云朵图标（没有勾）
    if (asset.isRemoteOnly) {
      return Positioned(
        top: 4,
        right: 4,
        child: _buildRemoteOnlyIcon(),
      );
    }
    
    // 获取资产的唯一标识符
    final assetId = asset.localId ?? asset.id;
    final hasRemote = asset.hasRemote;
    final checksum = asset.checksum; // 获取 checksum，用于查询远程资产表
    
    // 使用 Provider 获取上传状态（使用唯一标识符作为 family 参数）
    final statusAsync = ref.watch(
      assetUploadStatusProvider(assetId, hasRemote, checksum),
    );
    
    // 根据状态显示不同图标
    Widget iconWidget;
    
    if (statusAsync.isLoading) {
      // 加载中，显示默认图标（未上传）
      iconWidget = _buildNotUploadedIcon();
    } else if (statusAsync.hasError) {
      // 错误，显示默认图标
      iconWidget = _buildNotUploadedIcon();
    } else {
      final statusInfo = statusAsync.value!;
      
      switch (statusInfo.status) {
        case AssetUploadStatus.notUploaded:
          iconWidget = _buildNotUploadedIcon();
          break;
        case AssetUploadStatus.uploading:
          iconWidget = _buildUploadingIcon(statusInfo.progress);
          break;
        case AssetUploadStatus.uploaded:
          iconWidget = _buildUploadedIcon();
          break;
        case AssetUploadStatus.failed:
          iconWidget = _buildFailedIcon();
          break;
      }
    }
    
    return Positioned(
      top: 4,
      right: 4,
      child: iconWidget,
    );
  }
  
  /// 仅存在于服务端图标（云朵图标，中间没有勾）
  Widget _buildRemoteOnlyIcon() {
    return Icon(
      Icons.cloud_outlined,
      color: const Color.fromRGBO(255, 255, 255, 0.8),
      size: 16,
      shadows: const [
        Shadow(
          blurRadius: 5.0,
          color: Color.fromRGBO(0, 0, 0, 0.6),
          offset: Offset(0.0, 0.0),
        ),
      ],
    );
  }
  
  /// 未上传图标
  Widget _buildNotUploadedIcon() {
    return Icon(
      Icons.cloud_off_outlined,
      color: const Color.fromRGBO(255, 255, 255, 0.8),
      size: 16,
      shadows: const [
        Shadow(
          blurRadius: 5.0,
          color: Color.fromRGBO(0, 0, 0, 0.6),
          offset: Offset(0.0, 0.0),
        ),
      ],
    );
  }
  
  /// 上传中图标（带旋转动画）
  /// 使用 Stack 组合静态云图标和外围旋转圆环
  Widget _buildUploadingIcon(double? progress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 静态云图标
        Icon(
          Icons.cloud_upload_outlined,
          color: const Color.fromRGBO(255, 255, 255, 0.8),
          size: 16,
          shadows: const [
            Shadow(
              blurRadius: 5.0,
              color: Color.fromRGBO(0, 0, 0, 0.6),
              offset: Offset(0.0, 0.0),
            ),
          ],
        ),
        // 外围旋转圆环（无限旋转动画，不显示进度）
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            // 移除 value 参数，让圆环无限旋转
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color.fromRGBO(255, 255, 255, 0.8),
            ),
            backgroundColor: const Color.fromRGBO(255, 255, 255, 0.3),
          ),
        ),
      ],
    );
  }
  
  /// 已上传图标
  Widget _buildUploadedIcon() {
    return Icon(
      Icons.cloud_done_outlined,
      color: const Color.fromRGBO(255, 255, 255, 0.8),
      size: 16,
      shadows: const [
        Shadow(
          blurRadius: 5.0,
          color: Color.fromRGBO(0, 0, 0, 0.6),
          offset: Offset(0.0, 0.0),
        ),
      ],
    );
  }
  
  /// 上传失败图标（使用未上传图标，但颜色为红色）
  Widget _buildFailedIcon() {
    return Icon(
      Icons.cloud_off_outlined,
      color: Colors.red,
      size: 16,
      shadows: const [
        Shadow(
          blurRadius: 5.0,
          color: Color.fromRGBO(0, 0, 0, 0.6),
          offset: Offset(0.0, 0.0),
        ),
      ],
    );
  }
}


