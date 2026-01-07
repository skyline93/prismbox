// lib/services/asset/asset_service.dart

import 'dart:io' show Platform;
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart' show AssetEntity;
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/domain/entities/remote_asset.dart';

/// 资产视频尺寸信息
typedef _AssetVideoDimension = ({
  double? width,
  double? height,
  bool isFlipped,
});

/// 资产服务
/// 提供资产相关的业务逻辑，如宽高比计算
class AssetService {
  final LocalAssetDao _localAssetDao;
  final RemoteAssetDao _remoteAssetDao;
  final Logger _log = Logger('AssetService');

  AssetService({
    required LocalAssetDao localAssetDao,
    required RemoteAssetDao remoteAssetDao,
  }) : _localAssetDao = localAssetDao,
       _remoteAssetDao = remoteAssetDao;

  /// 获取资产的宽高比
  ///
  /// 如果 asset.aspectRatio 为 null，从数据库获取 width/height/orientation 后计算
  ///
  /// **参数**：
  /// - [asset] - 资产实体（LocalAsset 或 RemoteAsset）
  ///
  /// **返回**：宽高比（double），如果无法计算则返回 1.0
  Future<double> getAspectRatio(BaseAsset asset) async {
    try {
      final dimension = asset is LocalAsset
          ? await _getLocalAssetDimensions(asset)
          : await _getRemoteAssetDimensions(asset as RemoteAsset);

      if (dimension.width == null ||
          dimension.height == null ||
          dimension.height == 0) {
        _log.warning('getAspectRatio: 无法获取宽高信息，返回默认值 1.0, assetId=${asset.id}');
        return 1.0;
      }

      final aspectRatio = dimension.isFlipped
          ? dimension.height! / dimension.width!
          : dimension.width! / dimension.height!;

      _log.fine(
        'getAspectRatio: 计算宽高比成功, assetId=${asset.id}, aspectRatio=$aspectRatio, isFlipped=${dimension.isFlipped}',
      );

      return aspectRatio;
    } catch (e, stackTrace) {
      _log.severe(
        'getAspectRatio: 获取宽高比失败, assetId=${asset.id}',
        e,
        stackTrace,
      );
      return 1.0;
    }
  }

  /// 获取本地资产的尺寸信息
  ///
  /// 如果 width/height 为 null，从数据库获取
  /// 使用 orientation 计算 isFlipped（Android 上 90°/270° 需要交换）
  /// iOS 上，如果 AssetEntity 可用，直接使用其 width/height（已预校正）
  Future<_AssetVideoDimension> _getLocalAssetDimensions(
    LocalAsset asset,
  ) async {
    // iOS 特殊处理：优先使用 AssetEntity 的 width/height
    // 因为 iOS Photos framework 已经预校正了尺寸，AssetEntity 的 width/height 是最准确的
    // 这样可以修复数据库中已存在的旧数据（在方案1修改之前同步的，可能存储了错误的 width/height/orientation）
    if (Platform.isIOS) {
      AssetEntity? assetEntity = asset.assetEntity;

      // 如果 assetEntity 为 null，尝试异步加载（从数据库创建的 LocalAsset 可能没有 assetEntity）
      if (assetEntity == null) {
        try {
          assetEntity = await AssetEntity.fromId(asset.id);
          _log.fine(
            '_getLocalAssetDimensions: iOS 上异步加载 AssetEntity, assetId=${asset.id}',
          );
        } catch (e) {
          _log.warning(
            '_getLocalAssetDimensions: iOS 上加载 AssetEntity 失败, assetId=${asset.id}',
            e,
          );
        }
      }

      if (assetEntity != null) {
        final entityWidth = assetEntity.width;
        final entityHeight = assetEntity.height;

        if (entityWidth > 0 && entityHeight > 0) {
          _log.fine(
            '_getLocalAssetDimensions: iOS 上使用 AssetEntity 的宽高, assetId=${asset.id}, width=$entityWidth, height=$entityHeight',
          );
          // iOS 上，AssetEntity 的 width/height 已经预校正，不需要考虑 orientation
          return (
            width: entityWidth.toDouble(),
            height: entityHeight.toDouble(),
            isFlipped: false,
          );
        }
      }
    }

    double? width = asset.width?.toDouble();
    double? height = asset.height?.toDouble();
    int orientation = asset.orientation ?? 0;

    // 如果 width/height 为 null，从数据库获取
    if (width == null || height == null) {
      _log.fine(
        '_getLocalAssetDimensions: width/height 为 null，从数据库获取, assetId=${asset.id}',
      );
      final fetched = await _localAssetDao.getAssetById(asset.id);
      if (fetched != null) {
        width = fetched.width?.toDouble();
        height = fetched.height?.toDouble();
        orientation = fetched.orientation;
      }
    }

    // On Android, local assets need orientation correction for 90°/270° rotations
    // On iOS, the Photos framework pre-corrects dimensions
    final isFlipped =
        Platform.isAndroid && (orientation == 90 || orientation == 270);

    return (width: width, height: height, isFlipped: isFlipped);
  }

  /// 获取远程资产的尺寸信息
  ///
  /// 如果 width/height 为 null，从数据库获取
  /// 当前阶段简化处理：不考虑 orientation，直接使用 width/height
  Future<_AssetVideoDimension> _getRemoteAssetDimensions(
    RemoteAsset asset,
  ) async {
    double? width = asset.width?.toDouble();
    double? height = asset.height?.toDouble();

    // 如果 width/height 为 null，从数据库获取
    if (width == null || height == null) {
      _log.fine(
        '_getRemoteAssetDimensions: width/height 为 null，从数据库获取, assetId=${asset.id}',
      );
      final fetched = await _remoteAssetDao.getAssetById(asset.id);
      if (fetched != null) {
        width = fetched.width?.toDouble();
        height = fetched.height?.toDouble();
      }
    }

    // 当前阶段简化处理：不考虑 orientation
    // 后续可以扩展 EXIF 解析，但不在本次变更范围内
    final isFlipped = false;

    return (width: width, height: height, isFlipped: isFlipped);
  }
}
