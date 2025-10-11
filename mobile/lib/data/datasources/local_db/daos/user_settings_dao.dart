// lib/data/datasources/local_db/daos/user_settings_dao.dart

part of '../app_database.dart';

@DriftAccessor(tables: [UserSettings])
class UserSettingDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingDaoMixin {
  UserSettingDao(super.db);

  Future<void> upsertSetting(UserSettingsCompanion setting) {
    return into(userSettings).insertOnConflictUpdate(setting);
  }

  Future<String?> getSetting(String key) async {
    final setting = await (select(
      userSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return setting?.value;
  }

  Stream<List<UserSetting>> watchAllSettings() {
    return select(userSettings).watch();
  }

  Future<int> deleteSetting(String key) {
    return (delete(userSettings)..where((t) => t.key.equals(key))).go();
  }
}
