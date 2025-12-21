// lib/presentation/widgets/media/media_image_widget.dart

import 'package:flutter/material.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/media_loading/image_provider_factory.dart';
import 'package:prismbox/features/media_loading/mixins/cancellable_image_provider_mixin.dart';
import 'package:prismbox/presentation/widgets/media/gradient_placeholder_widget.dart';

/// 媒体图片组件
/// 用于显示媒体资源的图片，支持渐进式加载和错误处理
class MediaImageWidget extends StatefulWidget {
  /// 资产对象
  final BaseAsset asset;
  
  /// 是否显示缩略图（true）或原图（false）
  final bool isThumbnail;
  
  /// 目标尺寸
  final Size? size;
  
  /// 是否加载原图
  final bool loadOriginal;
  
  /// 服务器 URL
  final String? serverUrl;
  
  /// 图片适配方式
  final BoxFit fit;
  
  /// 占位符组件
  final Widget? placeholder;
  
  /// 错误组件
  final Widget? errorWidget;

  /// AssetEntity 加载器（可选，用于延迟获取）
  final AssetEntityLoader? assetEntityLoader;

  const MediaImageWidget({
    super.key,
    required this.asset,
    this.isThumbnail = true,
    this.size,
    this.loadOriginal = false,
    this.serverUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.assetEntityLoader,
  });

  @override
  State<MediaImageWidget> createState() => _MediaImageWidgetState();
}

class _MediaImageWidgetState extends State<MediaImageWidget> {
  ImageProvider? _imageProvider;
  bool _isLoading = false;

  // 性能优化：提取 TextStyle 为方法，避免在 build 中重复创建
  static TextStyle _buildErrorTextStyle(ColorScheme colorScheme) {
    return TextStyle(color: colorScheme.onSurface);
  }

  @override
  void initState() {
    super.initState();
    _loadImageProvider();
  }

  @override
  void didUpdateWidget(MediaImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果关键属性变化，重新加载
    if (oldWidget.asset.id != widget.asset.id ||
        oldWidget.isThumbnail != widget.isThumbnail ||
        oldWidget.loadOriginal != widget.loadOriginal ||
        oldWidget.serverUrl != widget.serverUrl ||
        oldWidget.assetEntityLoader != widget.assetEntityLoader) {
      _cancelCurrentLoading();
      _loadImageProvider();
    }
  }

  @override
  void dispose() {
    _cancelCurrentLoading();
    super.dispose();
  }

  /// 取消当前加载
  void _cancelCurrentLoading() {
    if (_imageProvider is CancellableImageProviderMixin) {
      (_imageProvider as CancellableImageProviderMixin).cancel();
    }
  }

  /// 加载图片提供者（支持异步获取 AssetEntity）
  Future<void> _loadImageProvider() async {
    final targetSize = widget.size ?? 
        (widget.isThumbnail ? kThumbnailResolution : const Size(1080, 1920));
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 获取 AssetEntityLoader
      final assetEntityLoader = widget.assetEntityLoader;
      
      // 尝试异步获取
      if (assetEntityLoader != null && widget.asset is LocalAsset) {
        final localAsset = widget.asset as LocalAsset;
        if (localAsset.assetEntity == null && widget.isThumbnail) {
          // 使用异步版本
          _imageProvider = await getThumbnailImageProviderAsync(
            widget.asset,
            size: targetSize,
            serverUrl: widget.serverUrl,
            assetEntityLoader: assetEntityLoader,
          );
        } else {
          // 已有 assetEntity 或不是缩略图，使用同步版本
          _imageProvider = widget.isThumbnail
              ? getThumbnailImageProvider(
                  widget.asset,
                  size: targetSize,
                  serverUrl: widget.serverUrl,
                )
              : getFullImageProvider(
                  widget.asset,
                  size: targetSize,
                  loadOriginal: widget.loadOriginal,
                  serverUrl: widget.serverUrl,
                );
        }
      } else {
        // 非 LocalAsset 或没有 loader，使用同步版本
        _imageProvider = widget.isThumbnail
            ? getThumbnailImageProvider(
                widget.asset,
                size: targetSize,
                serverUrl: widget.serverUrl,
              )
            : getFullImageProvider(
                widget.asset,
                size: targetSize,
                loadOriginal: widget.loadOriginal,
                serverUrl: widget.serverUrl,
              );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 获取占位符
    final placeholderProvider = getPlaceholderProvider(
      widget.asset,
      colorScheme: colorScheme,
    );
    final placeholderWidget = widget.placeholder ??
        (placeholderProvider != null
            ? Image(image: placeholderProvider, fit: widget.fit)
            : GradientPlaceholderWidget(colorScheme: colorScheme));

    // 如果正在加载或没有 provider，显示占位符
    if (_isLoading || _imageProvider == null) {
      return placeholderWidget;
    }

    return Image(
      image: _imageProvider!,
      fit: widget.fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Stack(
          children: [
            placeholderWidget,
            Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            Container(
              color: colorScheme.surfaceContainer,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '加载失败',
                    style: _buildErrorTextStyle(colorScheme),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
      },
    );
  }
}

