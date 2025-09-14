// lib/core/storage/sync_state_service.dart

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';

@LazySingleton()
class SyncStateService {
  final AppDatabase _db;

  // 定义存储在数据库中的 key
  static const _lastSyncTimestampKey = 'cloud_media_last_sync_timestamp';

  SyncStateService(this._db);

  /// 从数据库获取上次同步的时间戳。
  Future<DateTime?> getLastSyncTimestamp() async {
    final timestampString = await _db.userSettingDao.getSetting(
      _lastSyncTimestampKey,
    );
    if (timestampString == null) {
      return null;
    }
    // 安全地将字符串解析为 DateTime 对象
    return DateTime.tryParse(timestampString);
  }

  /// 将新的同步时间戳保存到数据库。
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    await _db.userSettingDao.upsertSetting(
      UserSettingsCompanion(
        key: const Value(_lastSyncTimestampKey),
        // 将 DateTime 对象转换为 ISO 8601 格式的字符串进行存储
        value: Value(timestamp.toIso8601String()),
      ),
    );
  }
}
