// lib/features/media_loading/thumbhash/gradient_placeholder_provider.dart

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';

/// 渐变占位符提供者
/// 作为 ThumbHash 的后备方案，生成基于主题色的渐变占位符
class GradientPlaceholderProvider extends ImageProvider<GradientPlaceholderProvider> {
  /// 颜色方案
  final ColorScheme colorScheme;
  
  /// 尺寸
  final Size size;

  final Logger _log = Logger('GradientPlaceholderProvider');

  GradientPlaceholderProvider({
    required this.colorScheme,
    this.size = const Size(200, 200),
  });

  @override
  Future<GradientPlaceholderProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    GradientPlaceholderProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _generateGradientImage(key, decode),
      scale: 1.0,
    );
  }

  /// 生成渐变图片
  Future<ui.Codec> _generateGradientImage(GradientPlaceholderProvider key, ImageDecoderCallback decode) async {
    try {
      // 创建 PictureRecorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 创建渐变
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          key.colorScheme.surfaceContainer,
          key.colorScheme.surfaceContainerHighest,
        ],
      );

      // 绘制渐变矩形
      final rect = Rect.fromLTWH(0, 0, key.size.width, key.size.height);
      canvas.drawRect(
        rect,
        Paint()..shader = gradient.createShader(rect),
      );

      // 转换为图片
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        key.size.width.toInt(),
        key.size.height.toInt(),
      );

      // 转换为 Codec
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to byte data');
      }
      final bytes = byteData.buffer.asUint8List();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final codec = await decode(buffer);

      return codec;
    } catch (e, stackTrace) {
      _log.severe('Failed to generate gradient placeholder', e, stackTrace);
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradientPlaceholderProvider &&
          runtimeType == other.runtimeType &&
          colorScheme == other.colorScheme &&
          size == other.size;

  @override
  int get hashCode => Object.hash(colorScheme, size);
}

