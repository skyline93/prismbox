part of '../app_database.dart';

@DriftAccessor(tables: [UserSettings])
class UserSettingDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingDaoMixin {
  UserSettingDao(AppDatabase db) : super(db);

  Future<void> upsertSetting(UserSettingsCompanion entry) {
    return into(userSettings).insertOnConflictUpdate(entry);
  }

  Future<String?> getSetting(String key) async {
    final setting = await (select(
      userSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return setting?.value;
  }

  Future<void> deleteSetting(String key) {
    return (delete(userSettings)..where((t) => t.key.equals(key))).go();
  }
}
