import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prismbox/widgets/photo_view.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/media_loading/image_provider_factory.dart';

/// 图片查看页面组件
///
/// 封装 PhotoView 相关逻辑，处理图片加载和错误状态，处理缩放状态回调。
class ViewerImagePage extends StatefulWidget {
  /// 资产对象
  final BaseAsset asset;

  /// 资产 ID
  final String assetId;

  /// 服务器 URL（可选）
  final String? serverUrl;

  /// AssetEntity 加载器（可选）
  final AssetEntityLoader? assetEntityLoader;

  /// 点击回调
  final VoidCallback? onTap;

  /// 缩放状态改变回调
  final ValueChanged<PhotoViewScaleState>? onScaleStateChanged;

  /// 长按回调（用于 Live Photo 长按播放）
  final VoidCallback? onLongPress;

  const ViewerImagePage({
    super.key,
    required this.asset,
    required this.assetId,
    this.serverUrl,
    this.assetEntityLoader,
    this.onTap,
    this.onScaleStateChanged,
    this.onLongPress,
  });

  @override
  State<ViewerImagePage> createState() => _ViewerImagePageState();
}

class _ViewerImagePageState extends State<ViewerImagePage> {
  static const _longPressDuration = Duration(milliseconds: 500);

  Timer? _longPressTimer;
  bool _longPressTriggered = false;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  /// 获取图片提供者
  ImageProvider _getImageProvider(BuildContext context) {
    try {
      // 获取屏幕尺寸用于优化加载
      final screenSize = MediaQuery.of(context).size;

      // 在查看器场景中，始终加载原图以确保清晰度
      // LocalFullImageProvider 的渐进式加载机制会：
      // 1. 先快速显示适配屏幕尺寸的图片（阶段2）
      // 2. 然后在后台加载原图（阶段3）
      // 这样可以避免闪烁，同时保证放大时的清晰度
      return getFullImageProvider(
        widget.asset,
        size: screenSize,
        loadOriginal: true, // 查看器场景始终加载原图
        serverUrl: widget.serverUrl,
        assetEntityLoader: widget.assetEntityLoader,
      );
    } catch (e) {
      // 如果找不到资源或获取失败，返回占位符
      return const NetworkImage('https://via.placeholder.com/800');
    }
  }

  void _handleTapDown(
    BuildContext context,
    TapDownDetails details,
    dynamic _,
  ) {
    // 启动长按计时器
    if (widget.onLongPress != null) {
      _longPressTimer?.cancel();
      _longPressTriggered = false;
      _longPressTimer = Timer(_longPressDuration, () {
        _longPressTriggered = true;
        widget.onLongPress?.call();
      });
    } else if (widget.onTap != null) {
      // 没有长按行为时，直接视为点击
      widget.onTap!.call();
    }
  }

  void _handleTapUp(
    BuildContext context,
    TapUpDetails details,
    dynamic _,
  ) {
    // 手指抬起时：若长按未触发且有 onTap，则视为普通点击
    if (_longPressTimer != null && _longPressTimer!.isActive) {
      _longPressTimer!.cancel();
      if (!_longPressTriggered && widget.onTap != null) {
        widget.onTap!.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      index: 0,
      imageProvider: _getImageProvider(context),
      heroAttributes: PhotoViewHeroAttributes(
        tag: 'asset_${widget.assetId}',
        transitionOnUserGestures: true,
      ),
      initialScale: PhotoViewComputedScale.contained * 0.99,
      minScale: PhotoViewComputedScale.contained * 0.99,
      maxScale: PhotoViewComputedScale.covered * 4.0,
      onTapDown: (widget.onTap != null || widget.onLongPress != null)
          ? _handleTapDown
          : null,
      onTapUp: (widget.onTap != null || widget.onLongPress != null)
          ? _handleTapUp
          : null,
      scaleStateChangedCallback: widget.onScaleStateChanged,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text('加载失败', style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      },
      loadingBuilder: (context, event, index) {
        if (event == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        final value =
            event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1);
        return Center(
          child: CircularProgressIndicator(value: value, color: Colors.white),
        );
      },
    );
  }
}
