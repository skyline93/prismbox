// lib/features/sync/replicator/media_sync_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_replicator/flutter_replicator.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/features/replicator/media_storage_adapter.dart';

/// MediaSyncService 负责管理媒体资源的同步流程。
/// 它初始化并协调 Replicator 实例来执行与后端的同步。
@lazySingleton
class MediaSyncService {
  late final Replicator _replicator;
  final _log = Logger('MediaSyncService');
  bool _isInitialized = false;

  MediaSyncService() {
    _initialize();
  }

  void _initialize() {
    if (_isInitialized) return;

    // 1. 从依赖注入容器(getIt)中获取全局 Dio 实例
    final Dio dioClient = getIt<Dio>();

    // 2. 创建 Replicator 配置
    // **特别说明：** 您需要提供一种安全的方式来获取当前设备的唯一ID和当前用户的ID。
    // 这里使用占位符，请务必替换为您的实际业务逻辑。
    // 例如: final deviceId = await DeviceInfoService.getId();
    // 例如: final userId = AuthService.getCurrentUserId();
    final replicatorConfig = ReplicatorConfig(
      // 当注入自定义 Dio 实例时，baseUrl 是可选的，因为 Dio 实例已经配置了它。
      deviceId: 'your_actual_device_id', // TODO: 替换为真实的设备ID
      userId: 'your_actual_user_id', // TODO: 替换为真实的用户ID
    );

    // 3. 实例化我们自定义的 StorageAdapter
    final storageAdapter = MediaStorageAdapter();

    // 4. 实例化 Replicator，并注入配置、存储适配器和自定义的 Dio 实例
    _replicator = Replicator(
      config: replicatorConfig,
      storage: storageAdapter,
      dio: dioClient,
    );

    _isInitialized = true;
    _log.info('MediaSyncService 初始化成功。');
  }

  /// 触发媒体资源的同步过程。
  ///
  /// Replicator 内部会自动判断是执行全量同步还是增量同步。
  /// 调用此方法是安全的，可以在任何需要同步的时候执行。
  Future<void> syncMediaAssets() async {
    _log.info('开始执行媒体资源同步...');
    try {
      await _replicator.sync();
      _log.info('媒体资源同步成功完成。');
    } catch (e, s) {
      _log.severe('媒体资源同步过程中发生错误。', e, s);
      // 重新抛出异常，以便UI层可以捕获并向用户显示反馈
      rethrow;
    }
  }
}
