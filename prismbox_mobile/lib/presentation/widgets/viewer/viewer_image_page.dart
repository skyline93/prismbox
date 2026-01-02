import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/media_loading/image_provider_factory.dart';

/// 图片查看页面组件
///
/// 封装 PhotoView 相关逻辑，处理图片加载和错误状态，处理缩放状态回调。
class ViewerImagePage extends StatelessWidget {
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

  const ViewerImagePage({
    super.key,
    required this.asset,
    required this.assetId,
    this.serverUrl,
    this.assetEntityLoader,
    this.onTap,
    this.onScaleStateChanged,
  });

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
        asset,
        size: screenSize,
        loadOriginal: true, // 查看器场景始终加载原图
        serverUrl: serverUrl,
        assetEntityLoader: assetEntityLoader,
      );
    } catch (e) {
      // 如果找不到资源或获取失败，返回占位符
      return const NetworkImage('https://via.placeholder.com/800');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: _getImageProvider(context),
      heroAttributes: PhotoViewHeroAttributes(
        tag: 'asset_$assetId',
        transitionOnUserGestures: true,
      ),
      initialScale: PhotoViewComputedScale.contained * 0.99,
      minScale: PhotoViewComputedScale.contained * 0.99,
      maxScale: PhotoViewComputedScale.covered * 4.0,
      onTapDown: onTap != null ? (_, __, ___) => onTap!() : null,
      scaleStateChangedCallback: onScaleStateChanged,
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
      loadingBuilder: (context, event) {
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

