// lib/services/asset/media_exif_extractor.dart

import 'dart:io';
import 'package:exif/exif.dart';
import 'package:logging/logging.dart';

/// 媒体 EXIF 元数据提取结果（用于写入本地表）
class MediaExifInfo {
  final String? deviceMake;
  final String? deviceModel;
  final String? exifExposureTime;
  final double? exifFNumber;
  final int? exifIso;
  final double? exifFocalLength;

  const MediaExifInfo({
    this.deviceMake,
    this.deviceModel,
    this.exifExposureTime,
    this.exifFNumber,
    this.exifIso,
    this.exifFocalLength,
  });
}

/// 从媒体文件中提取 EXIF（设备、拍摄参数）
/// 用于同步时写入 LocalAssetEntity 的媒体详细信息
class MediaExifExtractor {
  final Logger _logger = Logger('MediaExifExtractor');

  /// 从文件路径读取 EXIF，返回设备与拍摄参数；失败或非图片返回全 null
  Future<MediaExifInfo> extractFromPath(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const MediaExifInfo();
      }
      final bytes = await file.readAsBytes();
      return extractFromBytes(bytes);
    } catch (e) {
      _logger.fine('EXIF extract failed for $filePath: $e');
      return const MediaExifInfo();
    }
  }

  /// 从字节数组读取 EXIF（便于与 originFile 流配合）
  Future<MediaExifInfo> extractFromBytes(List<int> bytes) async {
    try {
      if (bytes.isEmpty) return const MediaExifInfo();
      final data = await readExifFromBytes(bytes);
      if (data.isEmpty) return const MediaExifInfo();

      String? deviceMake = _getString(data, 'Make') ?? _getString(data, 'Image Make');
      String? deviceModel = _getString(data, 'Model') ?? _getString(data, 'Image Model');
      String? exifExposureTime = _getString(data, 'ExposureTime') ?? _getString(data, 'EXIF ExposureTime');
      double? exifFNumber = _getRationalAsDouble(data, 'FNumber') ?? _getRationalAsDouble(data, 'EXIF FNumber');
      int? exifIso = _getInt(data, 'ISOSpeedRatings') ?? _getInt(data, 'EXIF ISOSpeedRatings');
      double? exifFocalLength = _getRationalAsDouble(data, 'FocalLength') ?? _getRationalAsDouble(data, 'EXIF FocalLength');

      return MediaExifInfo(
        deviceMake: deviceMake,
        deviceModel: deviceModel,
        exifExposureTime: exifExposureTime,
        exifFNumber: exifFNumber,
        exifIso: exifIso,
        exifFocalLength: exifFocalLength,
      );
    } catch (e) {
      _logger.fine('EXIF parse failed: $e');
      return const MediaExifInfo();
    }
  }

  String? _getString(Map<String, IfdTag> data, String key) {
    final tag = data[key];
    if (tag == null) return null;
    try {
      final v = tag.printable;
      return v.isNotEmpty ? v : null;
    } catch (_) {
      return null;
    }
  }

  int? _getInt(Map<String, IfdTag> data, String key) {
    final tag = data[key];
    if (tag == null) return null;
    try {
      final i = tag.values.firstAsInt();
      return i;
    } catch (_) {
      final s = tag.printable;
      if (s.isNotEmpty) return int.tryParse(s);
    }
    return null;
  }

  double? _getRationalAsDouble(Map<String, IfdTag> data, String key) {
    final tag = data[key];
    if (tag == null) return null;
    try {
      final list = tag.values.toList();
      if (list.length >= 2) {
        final numVal = list[0];
        final denVal = list[1];
        if (numVal is int && denVal is int && denVal != 0) {
          return numVal / denVal;
        }
      }
    } catch (_) {}
    try {
      final s = tag.printable;
      if (s.isNotEmpty) return double.tryParse(s);
    } catch (_) {}
    return null;
  }
}
