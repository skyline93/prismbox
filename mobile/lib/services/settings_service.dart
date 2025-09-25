import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/constants/settings_keys.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';

/// A service class to manage application-wide settings.
///
/// This class provides a type-safe interface for accessing and modifying
/// settings stored in the database via UserSettingDao. It follows the project's
/// pattern of receiving an AppDatabase instance and initializing its own DAO.
@lazySingleton
class SettingsService {
  final UserSettingDao _userSettingDao;

  // Constructor now takes AppDatabase, just like UploadService.
  SettingsService(AppDatabase db) : _userSettingDao = db.userSettingDao;

  // --- Concurrent Uploads ---
  Future<int> getMaxConcurrentUploads() async {
    final value = await _userSettingDao.getSetting(
      SettingsKeys.maxConcurrentUploads,
    );
    // Default to 3 if not set or invalid
    return int.tryParse(value ?? '3') ?? 3;
  }

  Future<void> setMaxConcurrentUploads(int count) {
    return _userSettingDao.upsertSetting(
      UserSettingsCompanion(
        key: const Value(SettingsKeys.maxConcurrentUploads),
        value: Value(count.toString()),
      ),
    );
  }

  // --- Concurrent Downloads ---
  Future<int> getMaxConcurrentDownloads() async {
    final value = await _userSettingDao.getSetting(
      SettingsKeys.maxConcurrentDownloads,
    );
    // Default to 3 if not set or invalid
    return int.tryParse(value ?? '3') ?? 3;
  }

  Future<void> setMaxConcurrentDownloads(int count) {
    return _userSettingDao.upsertSetting(
      UserSettingsCompanion(
        key: const Value(SettingsKeys.maxConcurrentDownloads),
        value: Value(count.toString()),
      ),
    );
  }

  // --- Auto Backup ---
  Future<bool> isAutoBackupEnabled() async {
    final value = await _userSettingDao.getSetting(
      SettingsKeys.autoBackupEnabled,
    );
    // Default to false if not set
    return value == 'true';
  }

  Future<void> setAutoBackupEnabled(bool isEnabled) {
    return _userSettingDao.upsertSetting(
      UserSettingsCompanion(
        key: const Value(SettingsKeys.autoBackupEnabled),
        value: Value(isEnabled.toString()),
      ),
    );
  }
}
