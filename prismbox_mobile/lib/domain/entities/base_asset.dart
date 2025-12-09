// lib/domain/entities/base_asset.dart

import 'package:prismbox/data/database/enums/asset_type.dart';

/// 资产状态枚举
enum AssetState {
  /// 仅本地存在
  local,
  /// 仅远程存在
  remote,
  /// 本地和远程都存在
  merged,
}

/// 基础资产实体
/// 表示一个媒体资源（图片或视频），可以是本地、远程或两者都有
abstract class BaseAsset {
  /// 资产名称
  final String name;
  
  /// 文件哈希值（用于关联本地和远程资产）
  final String? checksum;
  
  /// 资产类型
  final AssetType type;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;
  
  /// 宽度（像素）
  final int? width;
  
  /// 高度（像素）
  final int? height;
  
  /// 时长（秒，仅视频）
  final int? durationInSeconds;
  
  /// 是否收藏
  final bool isFavorite;
  
  /// Live Photo 视频 ID
  final String? livePhotoVideoId;

  const BaseAsset({
    required this.name,
    required this.checksum,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.width,
    this.height,
    this.durationInSeconds,
    this.isFavorite = false,
    this.livePhotoVideoId,
  });

  /// 是否为图片
  bool get isImage => type == AssetType.image;

  /// 是否为视频
  bool get isVideo => type == AssetType.video;

  /// 是否为 Motion Photo
  bool get isMotionPhoto => livePhotoVideoId != null;

  /// 时长（Duration 对象）
  Duration get duration {
    final durationInSeconds = this.durationInSeconds;
    if (durationInSeconds != null) {
      return Duration(seconds: durationInSeconds);
    }
    return const Duration();
  }

  /// 是否有远程版本
  bool get hasRemote => storage == AssetState.remote || storage == AssetState.merged;

  /// 是否有本地版本
  bool get hasLocal => storage == AssetState.local || storage == AssetState.merged;

  /// 是否仅本地存在
  bool get isLocalOnly => storage == AssetState.local;

  /// 是否仅远程存在
  bool get isRemoteOnly => storage == AssetState.remote;

  /// 资产状态（由子类实现）
  AssetState get storage;

  /// 本地资产 ID（由子类实现）
  String? get localId;

  /// 远程资产 ID（由子类实现）
  String? get remoteId;

  /// Hero 动画标签
  String get heroTag;

  /// 资产 ID（用于统一标识）
  String get id;
}

