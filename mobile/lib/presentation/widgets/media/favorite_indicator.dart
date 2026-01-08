// lib/presentation/widgets/media/favorite_indicator.dart

import 'package:flutter/material.dart';

/// 收藏指示器组件
/// 在缩略图左下角显示心形图标，指示资产是否被收藏
///
/// 设计说明：
/// - 位置：左下角，距离左边和底边各 4px
/// - 图标：白色心形图标（Icons.favorite）
/// - 背景：半透明黑色圆形背景（opacity 0.5）
/// - 大小：图标 12px，容器 18px
class FavoriteIndicator extends StatelessWidget {
  /// 是否收藏
  final bool isFavorite;

  const FavoriteIndicator({super.key, required this.isFavorite});

  @override
  Widget build(BuildContext context) {
    // 如果未收藏，不显示任何内容
    if (!isFavorite) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 4,
      bottom: 4,
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 14),
      ),
    );
  }
}
