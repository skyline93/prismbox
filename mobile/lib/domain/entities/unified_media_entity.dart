// lib/domain/entities/unified_media_entity.dart

import 'package:equatable/equatable.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/data/models/media/media_model.dart';

class UnifiedMediaEntity extends Equatable {
  final int id;
  final String? localId;
  final String? cloudUuid;
  final SyncStatus syncStatus;
  final MediaType assetType;
  final String? filePath;
  final String? fileName;
  final int? width;
  final int? height;
  final int? durationSec;
  final DateTime createdAt;

  const UnifiedMediaEntity({
    required this.id,
    this.localId,
    this.cloudUuid,
    required this.syncStatus,
    required this.assetType,
    this.filePath,
    this.fileName,
    this.width,
    this.height,
    this.durationSec,
    required this.createdAt,
  });

  factory UnifiedMediaEntity.fromDbModel(MediaAsset dbAsset) {
    return UnifiedMediaEntity(
      id: dbAsset.id,
      localId: dbAsset.localId,
      cloudUuid: dbAsset.cloudUuid,
      syncStatus: dbAsset.syncStatus,
      assetType: dbAsset.assetType,
      filePath: dbAsset.filePath,
      // 注意：这里可能也需要从 dbAsset 映射 fileName
      fileName: dbAsset.fileName,
      width: dbAsset.width,
      height: dbAsset.height,
      durationSec: dbAsset.durationSec,
      createdAt: dbAsset.createdAt,
    );
  }

  // =======================================================================
  // ===                      ⭐️ 新增 copyWith 方法                      ===
  // =======================================================================
  UnifiedMediaEntity copyWith({
    int? id,
    String? localId,
    String? cloudUuid,
    SyncStatus? syncStatus,
    MediaType? assetType,
    String? filePath,
    String? fileName,
    int? width,
    int? height,
    int? durationSec,
    DateTime? createdAt,
  }) {
    return UnifiedMediaEntity(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      cloudUuid: cloudUuid ?? this.cloudUuid,
      syncStatus: syncStatus ?? this.syncStatus,
      assetType: assetType ?? this.assetType,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      width: width ?? this.width,
      height: height ?? this.height,
      durationSec: durationSec ?? this.durationSec,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isVideo => assetType == MediaType.video;

  DateTime get creationDate => createdAt;

  double get aspectRatio =>
      (width != null && height != null && height! > 0) ? width! / height! : 1.0;

  @override
  List<Object?> get props => [
    id,
    localId,
    cloudUuid,
    syncStatus,
    assetType,
    filePath,
    fileName,
    width,
    height,
    durationSec,
    createdAt,
  ];
}
