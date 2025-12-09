// lib/presentation/widgets/media/thumbnail_widget.dart

import 'package:flutter/material.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/media_loading/image_provider_factory.dart';
import 'package:prismbox/presentation/widgets/media/media_image_widget.dart';

/// 缩略图组件
/// 专门用于显示缩略图的便捷组件
class ThumbnailWidget extends StatelessWidget {
  /// 资产对象
  final BaseAsset asset;
  
  /// 尺寸
  final Size size;
  
  /// 服务器 URL
  final String? serverUrl;
  
  /// 图片适配方式
  final BoxFit fit;
  
  /// 占位符组件
  final Widget? placeholder;
  
  /// 错误组件
  final Widget? errorWidget;

  const ThumbnailWidget({
    super.key,
    required this.asset,
    this.size = kThumbnailResolution,
    this.serverUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return MediaImageWidget(
      asset: asset,
      isThumbnail: true,
      size: size,
      serverUrl: serverUrl,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}

