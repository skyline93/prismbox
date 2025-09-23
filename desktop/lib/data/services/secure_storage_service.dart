import 'package:drift/drift.dart' hide isNull;
import '../datasources/local/app_database.dart';

// @lazySingleton -> Removed injectable
class SecureStorageService {
  final AppDatabase _db;
  SecureStorageService(this._db);

  static const _accessTokenKey = 'album_access_token';
  static const _refreshTokenKey = 'album_refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _db.userSettingDao.upsertSetting(
      UserSettingsCompanion(
        key: const Value(_accessTokenKey),
        value: Value(accessToken),
      ),
    );
    await _db.userSettingDao.upsertSetting(
      UserSettingsCompanion(
        key: const Value(_refreshTokenKey),
        value: Value(refreshToken),
      ),
    );
  }

  Future<String?> getAccessToken() =>
      _db.userSettingDao.getSetting(_accessTokenKey);
  Future<String?> getRefreshToken() =>
      _db.userSettingDao.getSetting(_refreshTokenKey);

  Future<void> clearTokens() async {
    await _db.userSettingDao.deleteSetting(_accessTokenKey);
    await _db.userSettingDao.deleteSetting(_refreshTokenKey);
  }
}
