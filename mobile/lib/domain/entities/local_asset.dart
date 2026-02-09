// lib/domain/entities/local_asset.dart

import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:photo_manager/photo_manager.dart' hide AssetType;
import 'package:prismbox/utils/raw_format_utils.dart';

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
  /// 使用私有字段避免与 BaseAsset.orientation getter 的命名冲突
  final int _orientation;

  /// photo_manager 的 AssetEntity（可选，用于直接访问本地资源）
  final AssetEntity? assetEntity;

  /// 回收站路径（可选，用于已删除的资源）
  final String? trashPath;

  /// 文件大小（字节）
  final int? fileSize;

  /// 拍摄纬度
  final double? latitude;

  /// 拍摄经度
  final double? longitude;

  /// 设备品牌（EXIF Make）
  final String? deviceMake;

  /// 设备型号（EXIF Model）
  final String? deviceModel;

  /// 快门（EXIF ExposureTime）
  final String? exifExposureTime;

  /// 光圈（EXIF FNumber）
  final double? exifFNumber;

  /// ISO（EXIF ISOSpeedRatings）
  final int? exifIso;

  /// 焦距 mm（EXIF FocalLength）
  final double? exifFocalLength;

  /// 是否 HDR（EXIF/厂商标签，如 iOS HDR Image Type）
  final bool? isHdr;

  /// 是否为 RAW 照片
  ///
  /// 长期方案：优先从数据库字段传入；当前阶段通过文件名后缀检测，
  /// 与本地图片加载逻辑中的 RAW 检测保持一致。
  @override
  final bool isRaw;

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
    int orientation = 0,
    this.assetEntity,
    this.trashPath,
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
    this.isRaw = false,
  })  : _orientation = orientation,
        remoteAssetId = remoteId;

  @override
  String? get localId => id;

  @override
  String? get remoteId => remoteAssetId;

  @override
  AssetState get storage =>
      remoteId == null ? AssetState.local : AssetState.merged;

  @override
  String get heroTag => '${id}_${remoteId ?? checksum ?? ''}';

  @override
  int? get orientation => _orientation;

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
    String? trashPath,
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
    bool? isRaw,
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
      trashPath: trashPath,
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
      // 如果上层已经计算好了 isRaw（未来加入 DB 字段），优先使用；
      // 否则根据文件名后缀进行一次同步检测。
      isRaw: isRaw ?? RawFormatUtils.isRawByFileName(name),
    );
  }
}
