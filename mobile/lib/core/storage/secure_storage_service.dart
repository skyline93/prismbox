import 'package:drift/drift.dart' hide isNull; // 导入 Drift 以使用 Value()
import 'package:injectable/injectable.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart'; // 导入以使用 UserSettingDao

@lazySingleton
class SecureStorageService {
  // 1. 移除 flutter_secure_storage，改为依赖注入 UserSettingDao
  final AppDatabase _db;
  SecureStorageService(this._db);

  static const _accessTokenKey = 'album_access_token';
  static const _refreshTokenKey = 'album_refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // 2. 使用 DAO 的 upsert 方法保存 tokens
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

  // 3. 使用 DAO 的 get 方法读取 token
  Future<String?> getAccessToken() =>
      _db.userSettingDao.getSetting(_accessTokenKey);
  Future<String?> getRefreshToken() =>
      _db.userSettingDao.getSetting(_refreshTokenKey);

  Future<void> clearTokens() async {
    // 4. 使用 DAO 的 delete 方法删除 tokens
    await _db.userSettingDao.deleteSetting(_accessTokenKey);
    await _db.userSettingDao.deleteSetting(_refreshTokenKey);
  }
}
