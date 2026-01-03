// lib/domain/entities/local_asset.dart

import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:photo_manager/photo_manager.dart' hide AssetType;

/// 本地资产实体
class LocalAsset extends BaseAsset {
  /// 本地资产 ID（photo_manager 的 AssetEntity ID）
  @override
  final String id;
  
  /// 关联的远程资产 ID
  final String? remoteAssetId;
  
  /// 是否已上传（标识资产是否已成功上传到服务器）
  final bool isUploaded;
  
  /// 图片方向（EXIF 方向值，0-8）
  final int orientation;
  
  /// photo_manager 的 AssetEntity（可选，用于直接访问本地资源）
  final AssetEntity? assetEntity;

  const LocalAsset({
    required this.id,
    String? remoteId,
    required super.name,
    required super.checksum,
    required super.type,
    required super.createdAt,
    required super.updatedAt,
    super.width,
    super.height,
    super.durationInSeconds,
    super.isFavorite = false,
    super.livePhotoVideoId,
    this.isUploaded = false,
    this.orientation = 0,
    this.assetEntity,
  }) : remoteAssetId = remoteId;

  @override
  String? get localId => id;

  @override
  String? get remoteId => remoteAssetId;

  @override
  AssetState get storage => remoteId == null ? AssetState.local : AssetState.merged;

  @override
  String get heroTag => '${id}_${remoteId ?? checksum ?? ''}';

  /// 从数据库实体创建 LocalAsset
  factory LocalAsset.fromData({
    required String id,
    required String name,
    String? checksum,
    required AssetType type,
    required DateTime createdAt,
    required DateTime updatedAt,
    int? width,
    int? height,
    int? durationInSeconds,
    bool isFavorite = false,
    String? livePhotoVideoId,
    bool isUploaded = false,
    int orientation = 0,
    String? remoteAssetId,
    AssetEntity? assetEntity,
  }) {
    return LocalAsset(
      id: id,
      remoteId: remoteAssetId,
      name: name,
      checksum: checksum,
      type: type,
      createdAt: createdAt,
      updatedAt: updatedAt,
      width: width,
      height: height,
      durationInSeconds: durationInSeconds,
      isFavorite: isFavorite,
      livePhotoVideoId: livePhotoVideoId,
      isUploaded: isUploaded,
      orientation: orientation,
      assetEntity: assetEntity,
    );
  }
}

