import 'package:shared_preferences/shared_preferences.dart';

/// 一个专门用于管理和持久化同步状态的服务。
/// 目前只负责管理最后一次成功同步的时间戳。
class SyncStateService {
  final SharedPreferences _prefs;

  // 使用常量作为 key，避免硬编码字符串 ("magic strings")
  static const _lastSyncTimestampKey = 'last_sync_timestamp';

  SyncStateService(this._prefs);

  /// 获取最后一次成功同步的时间戳。
  ///
  /// 如果是第一次同步，将返回 null。
  Future<DateTime?> getLastSyncTimestamp() async {
    final timestampString = _prefs.getString(_lastSyncTimestampKey);
    if (timestampString == null) {
      return null;
    }
    return DateTime.tryParse(timestampString);
  }

  /// 设置（更新）最后一次成功同步的时间戳。
  ///
  /// 这个方法应该在一次云端同步成功完成后被调用。
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    await _prefs.setString(_lastSyncTimestampKey, timestamp.toIso8601String());
  }
}
