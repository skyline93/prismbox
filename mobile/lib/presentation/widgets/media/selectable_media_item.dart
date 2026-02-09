// lib/presentation/widgets/media/selectable_media_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/backup/models/asset_upload_status.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/presentation/widgets/media/favorite_indicator.dart'; // FavoriteIndicator, AssetFavoriteIndicator
import 'package:prismbox/presentation/widgets/media/media_image_widget.dart';
import 'package:prismbox/services/backup/providers/asset_upload_status_provider.dart';
import 'package:prismbox/utils/color_extensions.dart';
import 'package:prismbox/utils/duration_formatter.dart';

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
                color: widget.selectionActive && widget.isSelected
                    ? assetContainerColor
                    : Colors.transparent,
                border: widget.selectionActive && widget.isSelected
                    ? Border.all(color: assetContainerColor, width: 8)
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

            // 视频时长或 Live Photo 角标（右下角，互斥）
            if (widget.asset.isVideo)
              Positioned(
                bottom: 4,
                right: 4,
                child: _VideoIndicatorWithAsset(asset: widget.asset),
              )
            else if (widget.asset.isMotionPhoto)
              const Positioned(
                bottom: 4,
                right: 4,
                child: _LivePhotoIndicator(),
              )
            // RAW 照片角标（右下角，仅静态照片且为 RAW 时显示）
            else if (widget.asset.isImage && widget.asset.isRaw)
              const Positioned(
                bottom: 4,
                right: 4,
                child: _RawPhotoIndicator(),
              ),

            // 收藏指示器（左下角，按媒体表收藏字段单独监听，返回时间线后图标即时更新）
            AssetFavoriteIndicator(asset: widget.asset),
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
      key: ValueKey('hero_thumb_${asset.id}'),
      asset: asset,
      isThumbnail: true,
      serverUrl: serverUrl,
      assetEntityLoader: assetEntityLoader,
    );

    // Hero tag 与 MediaViewerPage 的 PhotoViewHeroAttributes 一致，实现淡出时预览收缩到缩略图（与 Immich 一致）
    final heroTag = 'asset_${asset.id}';

    final content = isSelected
        ? Container(
            decoration: BoxDecoration(
              color: assetContainerColor,
              borderRadius: const BorderRadius.all(Radius.circular(15.0)),
            ),
            child: image,
          )
        : image;

    return Hero(
      tag: heroTag,
      // 飞行期间源位置显示空占位，避免缩略图先消失再出现导致闪烁（与 Immich 一致）
      placeholderBuilder: (context, heroSize, child) =>
          SizedBox.fromSize(size: heroSize),
      // 飞行的 shuttle 使用预览页大图，收缩动画更连贯（pop 时 from=预览页 to=缩略图）
      flightShuttleBuilder: (context, animation, direction, fromContext, toContext) {
        final fromHero = fromContext.widget as Hero;
        return fromHero.child;
      },
      child: RepaintBoundary(child: content),
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
      child: Icon(Icons.check_circle_rounded, color: googleBlue, size: 16),
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
      return Positioned(top: 4, right: 4, child: _buildRemoteOnlyIcon());
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

    return Positioned(top: 4, right: 4, child: iconWidget);
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

/// 视频标识组件
/// 显示播放图标和视频时长（右下角）
class _VideoIndicatorWithAsset extends StatelessWidget {
  final BaseAsset asset;

  const _VideoIndicatorWithAsset({required this.asset});

  // 性能优化：使用静态常量
  static const _iconSize = 16.0;
  static const _textSize = 12.0;
  static const _padding = EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0);
  static const _iconColor = Color.fromRGBO(255, 255, 255, 1.0);
  static const _textColor = Color.fromRGBO(255, 255, 255, 1.0);
  static const _backgroundColor = Colors.transparent;
  static const _shadow = Shadow(
    blurRadius: 2.0,
    color: Color.fromRGBO(0, 0, 0, 0.8),
    offset: Offset(0.0, 1.0),
  );

  @override
  Widget build(BuildContext context) {
    // 格式化视频时长
    final durationText = DurationFormatter.formatDuration(
      asset.durationInSeconds,
    );

    // 如果没有时长信息，只显示播放图标
    if (durationText.isEmpty) {
      return Container(
        padding: _padding,
        decoration: const BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: _iconColor,
          size: _iconSize,
          shadows: [_shadow],
        ),
      );
    }

    // 显示播放图标和时长
    // 性能优化：使用 Row 而不是 Stack，避免不必要的层级
    // 使用 Color.fromARGB 替代 Opacity，避免 saveLayer
    return Container(
      padding: _padding,
      decoration: const BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_arrow_rounded,
            color: _iconColor,
            size: _iconSize,
            shadows: [_shadow],
          ),
          const SizedBox(width: 2),
          Text(
            durationText,
            style: const TextStyle(
              color: _textColor,
              fontSize: _textSize,
              fontWeight: FontWeight.w500,
              shadows: [_shadow],
            ),
          ),
        ],
      ),
    );
  }
}

/// Live Photo 角标（右下角，与视频时长角标互斥）
/// 语义：动态照片，便于无障碍
class _LivePhotoIndicator extends StatelessWidget {
  const _LivePhotoIndicator();

  static const _iconSize = 16.0;
  static const _padding =
      EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0);
  static const _iconColor = Color.fromRGBO(255, 255, 255, 1.0);
  static const _shadow = Shadow(
    blurRadius: 2.0,
    color: Color.fromRGBO(0, 0, 0, 0.8),
    offset: Offset(0.0, 1.0),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '动态照片',
      child: Container(
        padding: _padding,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: const Icon(
          Icons.motion_photos_on_rounded,
          color: _iconColor,
          size: _iconSize,
          shadows: [_shadow],
        ),
      ),
    );
  }
}

/// RAW 照片角标（右下角，与视频/Live Photo 互斥）
///
/// 语义：RAW 照片，便于无障碍和专业用户快速识别。
class _RawPhotoIndicator extends StatelessWidget {
  const _RawPhotoIndicator();

  // 与其他角标保持一致的尺寸/样式
  static const _iconSize = 12.0;
  static const _textColor = Color.fromRGBO(255, 255, 255, 1.0);
  static const _shadow = Shadow(
    blurRadius: 2.0,
    color: Color.fromRGBO(0, 0, 0, 0.8),
    offset: Offset(0.0, 1.0),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'RAW 照片',
      child: SizedBox(
        height: _iconSize,
        // 文本宽度略小于图标宽度即可，交给 Text 自适应
        child: const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'RAW',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _textColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              height: 1.0,
              shadows: [_shadow],
            ),
          ),
        ),
      ),
    );
  }
}
