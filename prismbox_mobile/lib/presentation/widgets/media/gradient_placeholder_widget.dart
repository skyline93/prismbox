// lib/presentation/widgets/media/gradient_placeholder_widget.dart

import 'package:flutter/material.dart';

/// 渐变占位符组件
/// 作为图片加载时的占位符，显示基于主题色的渐变
class GradientPlaceholderWidget extends StatelessWidget {
  /// 颜色方案
  final ColorScheme colorScheme;
  
  /// 尺寸
  final Size? size;

  const GradientPlaceholderWidget({
    super.key,
    required this.colorScheme,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size?.width,
      height: size?.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainer,
            colorScheme.surfaceContainerHighest,
          ],
        ),
      ),
    );
  }
}

