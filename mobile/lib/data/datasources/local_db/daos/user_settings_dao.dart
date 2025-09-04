// lib/data/datasources/local_db/daos/user_settings_dao.dart

part of '../app_database.dart';

@DriftAccessor(tables: [UserSettings])
class UserSettingDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingDaoMixin {
  UserSettingDao(super.db);

  /// 插入或更新一个设置项
  Future<void> upsertSetting(UserSettingsCompanion setting) {
    return into(userSettings).insertOnConflictUpdate(setting);
  }

  /// 根据 key 获取一个设置项的值
  Future<String?> getSetting(String key) async {
    final setting = await (select(
      userSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return setting?.value;
  }

  /// 根据 key 删除一个设置项
  Future<int> deleteSetting(String key) {
    return (delete(userSettings)..where((t) => t.key.equals(key))).go();
  }
}
