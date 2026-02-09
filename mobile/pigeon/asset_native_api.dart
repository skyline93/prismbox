// pigeon/asset_native_api.dart

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/asset_native_api.g.dart',
    swiftOut: 'ios/Runner/Assets/AssetNative.g.swift',
    swiftOptions: SwiftOptions(includeErrorClass: true),
    kotlinOut:
        'android/app/src/main/kotlin/app/prismbox/assets/AssetNative.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'app.prismbox.assets',
      includeErrorClass: true,
    ),
    dartOptions: DartOptions(),
    dartPackageName: 'prismbox',
  ),
)
/// 资产元数据
/// 包含资产 ID 和收藏状态等信息
class AssetMetadata {
  /// 资产 ID（本地资源标识符）
  final String id;

  /// 是否收藏
  final bool isFavorite;

  const AssetMetadata({required this.id, required this.isFavorite});
}

/// 资产原生 API
/// 从 Flutter 调用原生平台获取系统相册资产的元数据
@HostApi()
abstract class AssetNativeApi {
  /// 获取单个资产的收藏状态
  ///
  /// **参数**：
  /// - [assetId] - 资产 ID（本地资源标识符）
  ///
  /// **返回值**：
  /// - `bool` 表示资产是否被收藏
  /// - 如果资产不存在或获取失败，返回 `false`
  ///
  /// **平台说明**：
  /// - iOS：通过 PHAsset.isFavorite 属性获取
  /// - Android：通过 MediaStore.MediaColumns.IS_FAVORITE 字段查询（仅 Android 11+）
  /// - Android 10 及以下版本始终返回 false
  @async
  bool getIsFavorite(String assetId);

  /// 批量获取资产元数据
  ///
  /// **参数**：
  /// - [assetIds] - 资产 ID 列表
  ///
  /// **返回值**：
  /// - `List<AssetMetadata>` 包含每个资产的元数据
  /// - 如果某个资产不存在，该资产不会出现在结果中
  ///
  /// **性能说明**：
  /// - 批量获取比逐个调用 getIsFavorite 更高效
  /// - 建议每批不超过 100 个资产
  @async
  List<AssetMetadata> getAssetMetadata(List<String> assetIds);

  /// 设置系统相册中资产的收藏状态（写回系统，与 DB 一致以便下次同步不被覆盖）
  ///
  /// **参数**：
  /// - [assetId] - 资产 ID（iOS 为 localIdentifier，Android 为 MediaStore _ID）
  /// - [isFavorite] - 是否收藏
  ///
  /// **权限**：
  /// - iOS：需要相册「读写」权限（PHAuthorizationStatus 且 requestAccess 为 readWrite）
  /// - Android：需要存储/相册写入权限（Android 11+ 使用 MediaStore 更新 IS_FAVORITE）
  ///
  /// **失败**：无权限或资产不存在时通过异常返回，调用方应捕获并降级（仅保留 DB 更新）。
  @async
  void setIsFavorite(String assetId, bool isFavorite);
}
