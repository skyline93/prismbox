// lib/presentation/widgets/media/selectable_media_item.dart

import 'package:flutter/material.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/presentation/widgets/media/media_image_widget.dart';
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
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    // 计算选中时的容器颜色（与 Immich 保持一致）
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final assetContainerColor = isDarkTheme
        ? primaryColor.darken(amount: 0.6)
        : primaryColor.lighten(amount: 0.8);

    return GestureDetector(
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: assetContainerColor,
        borderRadius: const BorderRadius.all(Radius.circular(15.0)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(15.0)),
        child: image,
      ),
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
/// 根据 BaseAsset.hasRemote 显示不同的上传状态图标
class _UploadStatusIcon extends StatelessWidget {
  final BaseAsset asset;
  
  const _UploadStatusIcon({required this.asset});
  
  @override
  Widget build(BuildContext context) {
    // 根据 hasRemote 判断状态
    final isUploaded = asset.hasRemote;
    
    return Positioned(
      top: 8,
      right: 8,
      child: Icon(
        isUploaded 
          ? Icons.cloud_done_outlined 
          : Icons.cloud_off_outlined,
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
    );
  }
}

