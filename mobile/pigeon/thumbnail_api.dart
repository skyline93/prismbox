// pigeon/thumbnail_api.dart

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/thumbnail_api.g.dart',
    swiftOut: 'ios/Runner/Images/Thumbnails.g.swift',
    swiftOptions: SwiftOptions(includeErrorClass: true),
    kotlinOut:
        'android/app/src/main/kotlin/app/prismbox/images/Thumbnails.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'app.prismbox.images',
      includeErrorClass: true,
    ),
    dartOptions: DartOptions(),
    dartPackageName: 'prismbox',
  ),
)
/// 缩略图解码 API
/// 从 Flutter 调用原生平台的图片解码功能，支持 RAW 格式和视频缩略图
@HostApi()
abstract class ThumbnailApi {
  /// 请求图片解码
  ///
  /// **参数**：
  /// - [assetId] - 资源 ID（本地资源标识符）
  /// - [requestId] - 请求 ID（用于取消请求）
  /// - [width] - 目标宽度（像素）
  /// - [height] - 目标高度（像素）
  /// - [isVideo] - 是否为视频资源
  ///
  /// **返回值**：
  /// - `Map<String, int>` 包含：
  ///   - `pointer`: 原生内存指针地址
  ///   - `width`: 实际图片宽度
  ///   - `height`: 实际图片高度
  ///   - 空 Map 表示请求已取消
  @async
  Map<String, int> requestImage(
    String assetId, {
    required int requestId,
    required int width,
    required int height,
    required bool isVideo,
  });

  /// 取消图片请求
  ///
  /// **参数**：
  /// - [requestId] - 要取消的请求 ID
  void cancelImageRequest(int requestId);

  /// 解码 ThumbHash 为 RGBA 图片
  ///
  /// **参数**：
  /// - [thumbhash] - Base64 编码的 ThumbHash 字符串
  ///
  /// **返回值**：
  /// - `Map<String, int>` 包含：
  ///   - `pointer`: 原生内存指针地址
  ///   - `width`: 图片宽度
  ///   - `height`: 图片高度
  @async
  Map<String, int> getThumbhash(String thumbhash);
}
