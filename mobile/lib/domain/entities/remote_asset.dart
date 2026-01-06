// lib/domain/entities/remote_asset.dart

import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/asset_visibility.dart';

/// 远程资产实体
class RemoteAsset extends BaseAsset {
  /// 远程资产 ID（服务器端 ID）
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
  }) : localAssetId = localId;

  @override
  String? get localId => localAssetId;

  @override
  String? get remoteId => id;

  @override
  AssetState get storage => localId == null ? AssetState.remote : AssetState.merged;

  @override
  String get heroTag => '${localId ?? checksum ?? ''}_$id';

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
    );
  }
}

