// lib/core/storage/sync_state_service.dart

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@LazySingleton()
class SyncStateService {
  final SharedPreferences _prefs;

  static const _lastSyncTimestampKey = 'last_sync_timestamp';

  SyncStateService(this._prefs);

  Future<DateTime?> getLastSyncTimestamp() async {
    final timestampString = _prefs.getString(_lastSyncTimestampKey);
    if (timestampString == null) {
      return null;
    }
    return DateTime.tryParse(timestampString);
  }

  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    await _prefs.setString(_lastSyncTimestampKey, timestamp.toIso8601String());
  }
}
