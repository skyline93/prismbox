import 'package:equatable/equatable.dart';

// 导入您在 app_database.dart 中定义的枚举，以实现类型安全。
// 这是推荐的做法，因为它确保了 Domain 层和 Data 层对状态有共同的理解。
import 'package:mobile/data/datasources/app_database.dart';

/// 统一的媒体实体 (Unified Media Entity)
///
/// 这是 Domain 层和 Presentation 层（ViewModel, UI Widgets）使用的标准数据模型。
/// 它的主要职责是：
/// 1. **解耦**：将 UI 与具体的数据源（如 Drift 数据库的 `MediaAsset` 类、网络 API 的 DTO）隔离。
/// 2. **稳定契约**：为 UI 提供一个简洁、稳定的数据结构。即使底层数据源变化，只要到此模型的映射被更新，UI 代码就无需改动。
/// 3. **业务逻辑载体**：可以包含一些派生的 getter 或方法，用于封装纯粹的业务逻辑。
///
/// 使用 `Equatable` 可以方便地进行值的比较，这在状态管理（如 BLoC, Provider）中非常有用，可以避免不必要的 UI 重建。
class UnifiedMediaEntity extends Equatable {
  /// 数据库中的自增主键。是应用内部操作此实体的最可靠标识。
  final int id;

  /// 来自 photo_manager 的 ID，用于直接操作本地相册中的文件。
  /// 对于仅存在于云端的媒体，此值为 null。
  final String? localId;

  /// 来自服务器的 UUID，用于所有云端相关的操作（如删除、获取详情）。
  /// 对于仅存在于本地的媒体，此值为 null。
  final String? cloudUuid;

  /// 核心同步状态，直接驱动 UI 上各种角标（上传中、已同步、仅云端等）的显示。
  final SyncStatus syncStatus;

  /// 媒体类型（图片或视频）。
  final MediaType assetType;

  /// 本地文件的绝对路径。可用于通过 `File` 对象显示高分辨率图像或视频。
  /// 对于仅存在于云端的媒体，此值可能为 null。
  final String? filePath;

  /// 媒体的宽度（像素）。
  final int? width;

  /// 媒体的高度（像素）。
  final int? height;

  /// 视频的时长（秒）。对于图片，此值为 0 或 null。
  final int? durationSec;

  /// 媒体的原始创建时间（通常是照片的拍摄时间）。主要用于时间线排序。
  final DateTime createdAt;

  const UnifiedMediaEntity({
    required this.id,
    this.localId,
    this.cloudUuid,
    required this.syncStatus,
    required this.assetType,
    this.filePath,
    this.width,
    this.height,
    this.durationSec,
    required this.createdAt,
  });

  /// **核心转换逻辑**
  ///
  /// 这是一个工厂构造函数，负责将数据层模型 (`MediaAsset`) 转换为领域层实体 (`UnifiedMediaEntity`)。
  /// 这个转换过程由 `Repository` 层调用，是分层架构的关键实践。
  factory UnifiedMediaEntity.fromDbModel(MediaAsset dbAsset) {
    return UnifiedMediaEntity(
      id: dbAsset.id,
      localId: dbAsset.localId,
      cloudUuid: dbAsset.cloudUuid,
      syncStatus: dbAsset.syncStatus,
      assetType: dbAsset.assetType,
      filePath: dbAsset.filePath,
      width: dbAsset.width,
      height: dbAsset.height,
      durationSec: dbAsset.durationSec,
      createdAt: dbAsset.createdAt,
    );
  }

  /// 一个派生的 getter，封装业务逻辑，方便 UI 调用。
  bool get isVideo => assetType == MediaType.video;

  /// 另一个派生 getter，用于计算宽高比，防止除以零的错误。
  double get aspectRatio =>
      (width != null && height != null && height! > 0) ? width! / height! : 1.0;

  // `Equatable` 的配置。
  // 当比较两个 `UnifiedMediaEntity` 实例时，`Equatable` 会检查 `props` 列表中的所有字段是否相等。
  // 如果所有字段都相等，则两个实例被认为是相等的。
  @override
  List<Object?> get props => [
    id,
    localId,
    cloudUuid,
    syncStatus,
    assetType,
    filePath,
    width,
    height,
    durationSec,
    createdAt,
  ];
}
