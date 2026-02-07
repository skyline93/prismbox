// lib/presentation/widgets/viewer/media_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';

/// 单行信息：标签 + 值
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 媒体详细信息底部 sheet 内容
/// 展示拍摄设备、原文件名、文件大小、尺寸、拍摄位置、拍摄参数
class MediaDetailSheet extends StatelessWidget {
  final BaseAsset? asset;
  final ScrollController? scrollController;

  const MediaDetailSheet({super.key, this.asset, this.scrollController});

  static String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '—';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '$bytes B';
  }

  static String _formatDimensions(int? w, int? h) {
    if (w != null && h != null && w > 0 && h > 0) {
      return '$w × $h';
    }
    return '—';
  }

  static String _formatLocation(double? lat, double? lng) {
    if (lat != null && lng != null) {
      return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    }
    return '—';
  }

  static String _formatDevice(String? make, String? model) {
    if (make != null && make.isNotEmpty && model != null && model.isNotEmpty) {
      return '$make $model';
    }
    if (make != null && make.isNotEmpty) return make;
    if (model != null && model.isNotEmpty) return model;
    return '—';
  }

  static String _formatExifParams({
    String? exposureTime,
    double? fNumber,
    int? iso,
    double? focalLength,
  }) {
    final parts = <String>[];
    if (exposureTime != null && exposureTime.isNotEmpty) {
      parts.add('快门 $exposureTime');
    }
    if (fNumber != null && fNumber > 0) {
      parts.add('光圈 f/${fNumber.toStringAsFixed(1)}');
    }
    if (iso != null && iso > 0) {
      parts.add('ISO $iso');
    }
    if (focalLength != null && focalLength > 0) {
      parts.add('${focalLength.toStringAsFixed(0)} mm');
    }
    if (parts.isEmpty) return '—';
    return parts.join('  ');
  }

  @override
  Widget build(BuildContext context) {
    if (asset == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('暂无媒体信息')),
      );
    }

    final a = asset!;
    final theme = Theme.of(context);

    String device = '—';
    String originalFilename = (a.name.isNotEmpty) ? a.name : '—';
    String fileSizeStr = '—';
    String dimensionsStr = _formatDimensions(a.width, a.height);
    String locationStr = '—';
    String exifParamsStr = '—';

    if (a is LocalAsset) {
      device = _formatDevice(a.deviceMake, a.deviceModel);
      fileSizeStr = _formatFileSize(a.fileSize);
      locationStr = _formatLocation(a.latitude, a.longitude);
      exifParamsStr = _formatExifParams(
        exposureTime: a.exifExposureTime,
        fNumber: a.exifFNumber,
        iso: a.exifIso,
        focalLength: a.exifFocalLength,
      );
    }

    return ListView(
      controller: scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        _DetailRow(label: '拍摄设备', value: device),
        _DetailRow(label: '原文件名', value: originalFilename),
        _DetailRow(label: '文件大小', value: fileSizeStr),
        _DetailRow(label: '尺寸', value: dimensionsStr),
        _DetailRow(label: '拍摄位置', value: locationStr),
        _DetailRow(label: '拍摄参数', value: exifParamsStr),
      ],
    );
  }
}
