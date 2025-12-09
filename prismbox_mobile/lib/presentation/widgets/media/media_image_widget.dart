// lib/presentation/widgets/media/media_image_widget.dart

import 'package:flutter/material.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
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
  });

  @override
  State<MediaImageWidget> createState() => _MediaImageWidgetState();
}

class _MediaImageWidgetState extends State<MediaImageWidget> {
  ImageProvider? _imageProvider;

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
        oldWidget.serverUrl != widget.serverUrl) {
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

  /// 加载图片提供者
  void _loadImageProvider() {
    final targetSize = widget.size ?? (widget.isThumbnail ? kThumbnailResolution : const Size(1080, 1920));
    
    _imageProvider = widget.isThumbnail
        ? getThumbnailImageProvider(widget.asset, size: targetSize, serverUrl: widget.serverUrl)
        : getFullImageProvider(
            widget.asset,
            size: targetSize,
            loadOriginal: widget.loadOriginal,
            serverUrl: widget.serverUrl,
          );
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

    if (_imageProvider == null) {
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
                    style: TextStyle(color: colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
      },
    );
  }
}

