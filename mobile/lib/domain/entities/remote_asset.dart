// lib/domain/entities/remote_asset.dart

import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/asset_visibility.dart';

/// 远程资产实体
class RemoteAsset extends BaseAsset {
  /// 远程资产 ID（服务器端 ID）
  @override
  final String id;
  
  /// 关联的本地资产 ID
  final String? localAssetId;
  
  /// ThumbHash（用于生成占位符）
  final String? thumbHash;
  
  /// 可见性
  final AssetVisibility visibility;
  
  /// 所有者用户 ID
  final String ownerId;
  
  /// 堆叠 ID
  final String? stackId;

  /// 媒体详情（与 LocalAsset 一致，同步时写入，便于仅远程媒体在预览中展示）
  final int? fileSize;
  final double? latitude;
  final double? longitude;
  final String? deviceMake;
  final String? deviceModel;
  final String? exifExposureTime;
  final double? exifFNumber;
  final int? exifIso;
  final double? exifFocalLength;

  /// 是否 HDR（同步自服务器或 EXIF）
  final bool? isHdr;

  const RemoteAsset({
    required this.id,
    String? localId,
    required super.name,
    required this.ownerId,
    required super.checksum,
    required super.type,
    required super.createdAt,
    required super.updatedAt,
    super.width,
    super.height,
    super.durationInSeconds,
    super.isFavorite = false,
    this.thumbHash,
    this.visibility = AssetVisibility.private,
    super.livePhotoVideoId,
    this.stackId,
    this.fileSize,
    this.latitude,
    this.longitude,
    this.deviceMake,
    this.deviceModel,
    this.exifExposureTime,
    this.exifFNumber,
    this.exifIso,
    this.exifFocalLength,
    this.isHdr,
  }) : localAssetId = localId;

  @override
  String? get localId => localAssetId;

  @override
  String? get remoteId => id;

  @override
  AssetState get storage =>
      localId == null ? AssetState.remote : AssetState.merged;

  @override
  String get heroTag => '${localId ?? checksum ?? ''}_$id';

  @override
  int? get orientation => null; // RemoteAsset 没有 orientation，需要从 EXIF 获取（当前阶段不实现）

  /// 从数据库实体创建 RemoteAsset
  factory RemoteAsset.fromData({
    required String id,
    required String name,
    required String checksum,
    required String ownerId,
    required AssetType type,
    required DateTime createdAt,
    required DateTime updatedAt,
    int? width,
    int? height,
    int? durationInSeconds,
    bool isFavorite = false,
    String? thumbHash,
    AssetVisibility visibility = AssetVisibility.private,
    String? livePhotoVideoId,
    String? stackId,
    String? localAssetId,
    int? fileSize,
    double? latitude,
    double? longitude,
    String? deviceMake,
    String? deviceModel,
    String? exifExposureTime,
    double? exifFNumber,
    int? exifIso,
    double? exifFocalLength,
    bool? isHdr,
  }) {
    return RemoteAsset(
      id: id,
      localId: localAssetId,
      name: name,
      ownerId: ownerId,
      checksum: checksum,
      type: type,
      createdAt: createdAt,
      updatedAt: updatedAt,
      width: width,
      height: height,
      durationInSeconds: durationInSeconds,
      isFavorite: isFavorite,
      thumbHash: thumbHash,
      visibility: visibility,
      livePhotoVideoId: livePhotoVideoId,
      stackId: stackId,
      fileSize: fileSize,
      latitude: latitude,
      longitude: longitude,
      deviceMake: deviceMake,
      deviceModel: deviceModel,
      exifExposureTime: exifExposureTime,
      exifFNumber: exifFNumber,
      exifIso: exifIso,
      exifFocalLength: exifFocalLength,
      isHdr: isHdr,
    );
  }
}
