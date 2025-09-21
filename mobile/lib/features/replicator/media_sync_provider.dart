// lib/features/sync/replicator/media_sync_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_replicator/flutter_replicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:mobile/features/replicator/media_storage_adapter.dart';
// **特别说明**: 您需要确保 dioClientProvider 可以从下面的路径导入。
// 请根据您项目的实际结构调整此 import 路径。
import 'package:mobile/providers/providers.dart'; // 假设您的 dioClientProvider 在这里
import 'package:mobile/providers/user_profile_provider.dart';
import 'package:mobile/utils/device_utils.dart';

/// Riverpod Provider，用于创建和提供 MediaSyncService 的单例。
final mediaSyncServiceProvider = FutureProvider<MediaSyncService>((ref) async {
  // 1. 按照您提供的范例，从 Riverpod 监听并获取 Dio 实例
  final dio = ref.watch(dioClientProvider).dio;

  // final deviceInfoService = ref.watch(deviceInfoServiceProvider);
  // final deviceId = await deviceInfoService.getDeviceId();
  final info = await DeviceUtils.getDeviceInfo();

  final userRepository = ref.watch(userRepositoryProvider);
  final user = await userRepository.getCurrentUser();

  // 2. **特别说明: 依赖其他 Provider 获取设备和用户信息**
  //    为了更好的架构，建议您同样使用 Provider 来管理设备ID和用户ID。
  //    这里使用占位符，请替换为对您实际 Provider 的引用。
  //    例如:
  //    final deviceId = ref.watch(deviceInfoServiceProvider).getDeviceId();
  //    final userId = ref.watch(authNotifierProvider).currentUser?.id;
  // const String deviceId = 'your_actual_device_id'; // TODO: 替换为真实的设备ID
  // const String userId = 'your_actual_user_id'; // TODO: 替换为真实的用户ID

  return MediaSyncService(
    dio,
    deviceId: info["deviceId"]!,
    userId: '${user.id}',
  );
});

/// MediaSyncService 负责管理媒体资源的同步流程。
/// 它初始化并协调 Replicator 实例来执行与后端的同步。
class MediaSyncService {
  late final Replicator _replicator;
  final _log = Logger('MediaSyncService');
  bool _isInitialized = false;

  MediaSyncService(
    Dio dio, {
    required String deviceId,
    required String userId,
  }) {
    _initialize(dio, deviceId: deviceId, userId: userId);
  }

  void _initialize(
    Dio dio, {
    required String deviceId,
    required String userId,
  }) {
    if (_isInitialized) return;

    // 创建 Replicator 配置
    final replicatorConfig = ReplicatorConfig(
      deviceId: deviceId,
      userId: userId,
    );

    // 实例化我们自定义的 StorageAdapter
    final storageAdapter = MediaStorageAdapter();

    // 实例化 Replicator，并注入所有依赖
    _replicator = Replicator(
      config: replicatorConfig,
      storage: storageAdapter,
      dio: dio,
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
