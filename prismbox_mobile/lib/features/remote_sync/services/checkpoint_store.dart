// lib/features/remote_sync/services/checkpoint_store.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/sync_checkpoint_dao.dart';

/// 检查点存储服务
/// 负责管理同步检查点的本地存储
class CheckpointStore {
  final AppDatabase _database;
  final Logger _logger = Logger('CheckpointStore');
  SyncCheckpointDao? _dao;

  CheckpointStore(this._database);

  /// 获取 DAO 实例（延迟初始化）
  SyncCheckpointDao get _checkpointDao {
    _dao ??= SyncCheckpointDao(_database);
    return _dao!;
  }

  /// 获取检查点
  /// 
  /// [userId] 用户 ID
  /// [syncType] 同步类型（如 "assets_v1"）
  /// 
  /// 返回检查点 ID，如果不存在则返回 null
  Future<String?> getCheckpoint(String userId, String syncType) async {
    try {
      final checkpoint = await _checkpointDao.getCheckpoint(userId, syncType);
      return checkpoint?.ack;
    } catch (e, stackTrace) {
      _logger.severe('获取检查点失败', e, stackTrace);
      return null;
    }
  }

  /// 设置检查点
  /// 
  /// [userId] 用户 ID
  /// [syncType] 同步类型（如 "assets_v1"）
  /// [ack] 检查点 ID
  Future<void> setCheckpoint(
    String userId,
    String syncType,
    String ack,
  ) async {
    try {
      await _checkpointDao.setCheckpoint(userId, syncType, ack);
      _logger.fine('设置检查点成功: $syncType = $ack');
    } catch (e, stackTrace) {
      _logger.severe('设置检查点失败', e, stackTrace);
      rethrow;
    }
  }

  /// 清除检查点
  /// 
  /// [userId] 用户 ID
  /// [syncType] 同步类型（如 "assets_v1"）
  Future<void> clearCheckpoint(String userId, String syncType) async {
    try {
      await _checkpointDao.clearCheckpoint(userId, syncType);
      _logger.fine('清除检查点成功: $syncType');
    } catch (e, stackTrace) {
      _logger.severe('清除检查点失败', e, stackTrace);
      rethrow;
    }
  }

  /// 清除用户的所有检查点
  /// 
  /// [userId] 用户 ID
  Future<void> clearAllCheckpoints(String userId) async {
    try {
      await _checkpointDao.clearAllCheckpoints(userId);
      _logger.fine('清除所有检查点成功');
    } catch (e, stackTrace) {
      _logger.severe('清除所有检查点失败', e, stackTrace);
      rethrow;
    }
  }
}

