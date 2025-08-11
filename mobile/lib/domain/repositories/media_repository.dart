import 'dart:typed_data';
import '../entities/unified_media_entity.dart';

/// MediaRepository 的抽象接口（契约）。
///
/// 定义了数据层必须实现的功能。ViewModel 和 UseCase 将依赖此抽象接口，
/// 而不是具体的实现类，从而实现依赖倒置原则。
abstract class MediaRepository {
  /// 监听一个合并后的、统一的媒体实体列表流。
  ///
  /// 这是 UI 数据的主要来源。每当本地数据库发生变化（增、删、改），
  /// 此流都会发出一个新的列表，驱动 UI 实时刷新。
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream();

  /// 触发一次对设备本地媒体库的扫描与索引。
  ///
  /// 这个过程是异步的，并且是实现 "Local-First" 原则的关键。它会对比设备相册和
  /// 本地数据库，执行增量添加和清理操作。操作完成后，`getUnifiedMediaStream`
  /// 会自动发出更新后的数据。
  Future<void> loadAndIndexLocalMedia();

  /// 触发一次与云端的数据同步。
  ///
  /// 此方法会从云端拉取所有（或增量）媒体元数据，
  /// 并将其与本地数据库进行合并。
  Future<void> syncWithCloud();

  Future<Uint8List> downloadThumbnail(String uuid);

  // 未来可以添加更多方法...
  // Future<void> markAsPendingBackup(List<int> assetIds);
  // Future<void> deleteMedia(UnifiedMediaEntity entity);
  // Future<void> syncWithCloud();
}
