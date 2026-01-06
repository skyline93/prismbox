// lib/features/media_loading/thumbhash/thumbhash_decoder.dart

import 'dart:math' as math;
import 'dart:typed_data';

/// ThumbHash 解码器
/// 实现完整的 ThumbHash 解码算法，包括 DCT 变换
class ThumbHashDecoder {
  /// 解码 ThumbHash 为 RGBA 图片数据
  /// 
  /// [thumbHash] ThumbHash 字节数组
  /// 
  /// 返回包含宽度、高度和像素数据的解码结果
  static DecodedThumbHash decode(Uint8List thumbHash) {
    if (thumbHash.length < 5) {
      throw ArgumentError('ThumbHash too short');
    }

    // 读取头部信息
    final header24 = (thumbHash[0] & 255) |
        ((thumbHash[1] & 255) << 8) |
        ((thumbHash[2] & 255) << 16);
    final header16 = (thumbHash[3] & 255) | ((thumbHash[4] & 255) << 8);

    // 解析头部
    final lDc = (header24 & 63) / 63.0;
    final pDc = ((header24 >> 6) & 63) / 31.5 - 1.0;
    final qDc = ((header24 >> 12) & 63) / 31.5 - 1.0;
    final lScale = ((header24 >> 18) & 31) / 31.0;
    final hasAlpha = (header24 >> 23) != 0;
    final pScale = ((header16 >> 3) & 63) / 63.0;
    final qScale = ((header16 >> 9) & 63) / 63.0;
    final isLandscape = (header16 >> 15) != 0;
    final lx = math.max(3, isLandscape ? (hasAlpha ? 5 : 7) : (header16 & 7));
    final ly = math.max(3, isLandscape ? (header16 & 7) : (hasAlpha ? 5 : 7));
    final aDc = hasAlpha ? (thumbHash[5] & 15) / 15.0 : 1.0;
    final aScale = hasAlpha ? ((thumbHash[5] >> 4) & 15) / 15.0 : 0.0;

    // 读取变化的因子（增强饱和度 1.25x 以补偿量化）
    final acStart = hasAlpha ? 6 : 5;
    int acIndex = 0;

    final lChannel = Channel(lx, ly);
    final pChannel = Channel(3, 3);
    final qChannel = Channel(3, 3);
    Channel? aChannel;

    acIndex = lChannel.decode(thumbHash, acStart, acIndex, lScale);
    acIndex = pChannel.decode(thumbHash, acStart, acIndex, pScale * 1.25);
    acIndex = qChannel.decode(thumbHash, acStart, acIndex, qScale * 1.25);
    if (hasAlpha) {
      aChannel = Channel(5, 5);
      aChannel.decode(thumbHash, acStart, acIndex, aScale);
    }

    // 使用 DCT 解码为 RGB
    final ratio = _thumbHashToApproximateAspectRatio(thumbHash);
    final w = (ratio > 1.0 ? 32.0 : 32.0 * ratio).round();
    final h = (ratio > 1.0 ? 32.0 / ratio : 32.0).round();
    final rgba = Uint8List(w * h * 4);

    final cxStop = math.max(lx, hasAlpha ? 5 : 3);
    final cyStop = math.max(ly, hasAlpha ? 5 : 3);
    final fx = List<double>.filled(cxStop, 0.0);
    final fy = List<double>.filled(cyStop, 0.0);

    for (int y = 0, i = 0; y < h; y++) {
      for (int x = 0; x < w; x++, i += 4) {
        double l = lDc, p = pDc, q = qDc, a = aDc;

        // 预计算系数
        for (int cx = 0; cx < cxStop; cx++) {
          fx[cx] = math.cos(math.pi / w * (x + 0.5) * cx);
        }
        for (int cy = 0; cy < cyStop; cy++) {
          fy[cy] = math.cos(math.pi / h * (y + 0.5) * cy);
        }

        // 解码 L
        for (int cy = 0, j = 0; cy < ly; cy++) {
          final fy2 = fy[cy] * 2.0;
          for (int cx = cy > 0 ? 0 : 1; cx * ly < lx * (ly - cy); cx++, j++) {
            l += lChannel.ac[j] * fx[cx] * fy2;
          }
        }

        // 解码 P 和 Q
        for (int cy = 0, j = 0; cy < 3; cy++) {
          final fy2 = fy[cy] * 2.0;
          for (int cx = cy > 0 ? 0 : 1; cx < 3 - cy; cx++, j++) {
            final f = fx[cx] * fy2;
            p += pChannel.ac[j] * f;
            q += qChannel.ac[j] * f;
          }
        }

        // 解码 A
        if (hasAlpha && aChannel != null) {
          for (int cy = 0, j = 0; cy < 5; cy++) {
            final fy2 = fy[cy] * 2.0;
            for (int cx = cy > 0 ? 0 : 1; cx < 5 - cy; cx++, j++) {
              a += aChannel.ac[j] * fx[cx] * fy2;
            }
          }
        }

        // 转换为 RGB
        final b = l - 2.0 / 3.0 * p;
        final r = (3.0 * l - b + q) / 2.0;
        final g = r - q;

        // 限制范围并转换为字节
        rgba[i] = (_clamp(r * 255.0, 0.0, 255.0)).round();
        rgba[i + 1] = (_clamp(g * 255.0, 0.0, 255.0)).round();
        rgba[i + 2] = (_clamp(b * 255.0, 0.0, 255.0)).round();
        rgba[i + 3] = (_clamp(a * 255.0, 0.0, 255.0)).round();
      }
    }

    return DecodedThumbHash(width: w, height: h, rgba: rgba);
  }

  /// 从 ThumbHash 计算近似宽高比
  static double _thumbHashToApproximateAspectRatio(Uint8List thumbHash) {
    if (thumbHash.length < 4) return 1.0;
    final header16 = (thumbHash[3] & 255) | ((thumbHash[4] & 255) << 8);
    final isLandscape = (header16 >> 15) != 0;
    final lx = isLandscape ? 7 : (header16 & 7);
    final ly = isLandscape ? (header16 & 7) : 7;
    return lx.toDouble() / ly.toDouble();
  }

  static double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

/// 解码后的 ThumbHash 数据
class DecodedThumbHash {
  final int width;
  final int height;
  final Uint8List rgba;

  DecodedThumbHash({
    required this.width,
    required this.height,
    required this.rgba,
  });
}

/// 通道数据（用于 DCT 解码）
class Channel {
  final int nx;
  final int ny;
  final List<double> ac;

  Channel(this.nx, this.ny) : ac = List<double>.filled(nx * ny, 0.0);

  /// 解码通道数据
  int decode(Uint8List data, int start, int acIndex, double scale) {
    for (int cy = 0; cy < ny; cy++) {
      for (int cx = cy > 0 ? 0 : 1; cx * ny < nx * (ny - cy); cx++) {
        final value = _readVarInt(data, start + acIndex);
        acIndex = value.index;
        ac[cx + cy * nx] = value.value * scale;
      }
    }
    return acIndex;
  }

  /// 读取变长整数
  static _VarIntResult _readVarInt(Uint8List data, int index) {
    int result = 0;
    int shift = 0;
    int currentIndex = index;

    while (currentIndex < data.length) {
      final byte = data[currentIndex] & 255;
      currentIndex++;
      result |= (byte & 127) << shift;
      if ((byte & 128) == 0) {
        // 符号扩展
        if (result > (1 << 30)) {
          result -= (1 << 31);
        }
        return _VarIntResult(currentIndex, result.toDouble());
      }
      shift += 7;
      if (shift >= 35) {
        throw ArgumentError('Invalid varint');
      }
    }

    throw ArgumentError('Unexpected end of data');
  }
}

/// 变长整数读取结果
class _VarIntResult {
  final int index;
  final double value;

  _VarIntResult(this.index, this.value);
}

