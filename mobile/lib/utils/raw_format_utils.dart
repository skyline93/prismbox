// lib/utils/raw_format_utils.dart
//
// RAW 格式检测工具
// 目前通过文件名后缀来判断是否为 RAW 格式，逻辑与
// `LocalImageRequest._isRawFormat` 中使用的扩展名列表保持一致，
// 方便在实体层/界面层复用而无需依赖异步操作。

/// RAW 格式检测工具类
class RawFormatUtils {
  /// 常见 RAW 格式扩展名（全部小写，包含点号）
  static const List<String> rawExtensions = [
    '.dng',
    '.cr2',
    '.cr3',
    '.nef',
    '.arw',
    '.orf',
    '.raf',
    '.rw2',
    '.pef',
    '.srw',
    '.3fr',
    '.erf',
    '.mrw',
    '.nrw',
    '.kdc',
    '.dcr',
    '.raw',
    '.x3f',
    '.fff',
    '.iiq',
    '.ari',
    '.cap',
    '.cin',
    '.crw',
  ];

  /// 根据文件名判断是否为 RAW 格式
  ///
  /// [fileName] 可以是完整路径或仅文件名，内部会统一转为小写，
  /// 并使用 [rawExtensions] 列表进行后缀匹配。
  static bool isRawByFileName(String? fileName) {
    if (fileName == null || fileName.isEmpty) {
      return false;
    }

    final lower = fileName.toLowerCase();
    return rawExtensions.any(lower.endsWith);
  }
}

