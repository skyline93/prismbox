// lib/features/media_loading/thumbhash/thumbhash_provider.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';
import 'package:prismbox/features/media_loading/thumbhash/thumbhash_decoder.dart';

/// ThumbHash 提供者
/// 用于解码 ThumbHash 并生成低分辨率占位图
class ThumbHashProvider extends ImageProvider<ThumbHashProvider> {
  /// ThumbHash 字节数组
  final Uint8List thumbHash;

  final Logger _log = Logger('ThumbHashProvider');

  ThumbHashProvider(this.thumbHash);

  @override
  Future<ThumbHashProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    ThumbHashProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _decodeThumbHash(key, decode),
      scale: 1.0,
    );
  }

  /// 解码 ThumbHash
  Future<ui.Codec> _decodeThumbHash(ThumbHashProvider key, ImageDecoderCallback decode) async {
    try {
      // 使用完整的 ThumbHash 解码器
      final decoded = ThumbHashDecoder.decode(key.thumbHash);
      
      // 将 RGBA 数据转换为图片
      final image = img.Image.fromBytes(
        width: decoded.width,
        height: decoded.height,
        bytes: decoded.rgba.buffer,
      );
      
      // 编码为 PNG
      final pngBytes = img.encodePng(image);
      
      // 创建 Codec
      final buffer = await ui.ImmutableBuffer.fromUint8List(pngBytes);
      return await decode(buffer);
    } catch (e, stackTrace) {
      _log.severe('Failed to decode ThumbHash', e, stackTrace);
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThumbHashProvider &&
          runtimeType == other.runtimeType &&
          _listEquals(thumbHash, other.thumbHash);

  @override
  int get hashCode => thumbHash.hashCode;

  /// 比较两个列表是否相等
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

