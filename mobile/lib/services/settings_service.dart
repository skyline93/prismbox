import 'dart:async';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/constants/settings_keys.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';

enum BackupFrequency { daily, weekly, hours, minutes }

class BackupSettings {
  final bool isAutoBackupEnabled;
  final BackupFrequency frequency;
  final bool isBackupOnWifiOnly;
  // 新增备份时间段字段
  final DateTime? backupStartDate;
  final DateTime? backupEndDate;

  BackupSettings({
    required this.isAutoBackupEnabled,
    required this.frequency,
    required this.isBackupOnWifiOnly,
    // 在构造函数中添加
    this.backupStartDate,
    this.backupEndDate,
  });
}

@lazySingleton
class SettingsService {
  final UserSettingDao _userSettingDao;

  SettingsService(AppDatabase db) : _userSettingDao = db.userSettingDao;

  Future<int> getMaxConcurrentUploads() async {
    final value = await _userSettingDao.getSetting(
      SettingsKeys.maxConcurrentUploads,
    );
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

  Future<int> getMaxConcurrentDownloads() async {
    final value = await _userSettingDao.getSetting(
      SettingsKeys.maxConcurrentDownloads,
    );
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

  Stream<BackupSettings> watchBackupSettings() {
    return _userSettingDao.watchAllSettings().map((settingsList) {
      final settingsMap = {for (var s in settingsList) s.key: s.value};

      final isEnabled = settingsMap[SettingsKeys.autoBackupEnabled] == 'true';
      final isWifiOnly = settingsMap[SettingsKeys.backupOnWifiOnly] != 'false';

      final frequencyString =
          settingsMap[SettingsKeys.backupFrequency] ??
          BackupFrequency.daily.name;
      final frequency = BackupFrequency.values.firstWhere(
        (e) => e.name == frequencyString,
        orElse: () => BackupFrequency.daily,
      );
      // 解析日期字符串
      final startDateString = settingsMap[SettingsKeys.backupStartDate];
      final endDateString = settingsMap[SettingsKeys.backupEndDate];
      final startDate = startDateString != null
          ? DateTime.tryParse(startDateString)
          : null;
      final endDate = endDateString != null
          ? DateTime.tryParse(endDateString)
          : null;

      return BackupSettings(
        isAutoBackupEnabled: isEnabled,
        frequency: frequency,
        isBackupOnWifiOnly: isWifiOnly,
        // 传递新值
        backupStartDate: startDate,
        backupEndDate: endDate,
      );
    }).distinct();
  }

  Future<bool> isAutoBackupEnabled() async {
    final value = await _userSettingDao.getSetting(
      SettingsKeys.autoBackupEnabled,
    );
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

  Future<BackupFrequency> getBackupFrequency() async {
    final value = await _userSettingDao.getSetting(
      SettingsKeys.backupFrequency,
    );
    return BackupFrequency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BackupFrequency.daily,
    );
  }

  Future<void> setBackupFrequency(BackupFrequency frequency) {
    return _userSettingDao.upsertSetting(
      UserSettingsCompanion(
        key: const Value(SettingsKeys.backupFrequency),
        value: Value(frequency.name),
      ),
    );
  }

  Future<bool> isBackupOnWifiOnly() async {
    final value = await _userSettingDao.getSetting(
      SettingsKeys.backupOnWifiOnly,
    );
    return value != 'false';
  }

  Future<void> setBackupOnWifiOnly(bool isWifiOnly) {
    return _userSettingDao.upsertSetting(
      UserSettingsCompanion(
        key: const Value(SettingsKeys.backupOnWifiOnly),
        value: Value(isWifiOnly.toString()),
      ),
    );
  }

  // --- 新增日期设置方法 ---
  Future<DateTime?> getBackupStartDate() async {
    final value = await _userSettingDao.getSetting(
      SettingsKeys.backupStartDate,
    );
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> setBackupStartDate(DateTime? date) {
    // 如果日期为 null，则删除该设置项
    if (date == null) {
      // 假设您已经在 UserSettingDao 中添加了 deleteSetting 方法
      return _userSettingDao.deleteSetting(SettingsKeys.backupStartDate);
    } else {
      // 如果日期存在，则更新或插入该设置项
      return _userSettingDao.upsertSetting(
        UserSettingsCompanion(
          key: const Value(SettingsKeys.backupStartDate),
          // 在这个分支中，date 绝对不是 null，因此 toIso8601String() 是安全的
          value: Value(date.toIso8601String()),
        ),
      );
    }
  }

  Future<DateTime?> getBackupEndDate() async {
    final value = await _userSettingDao.getSetting(SettingsKeys.backupEndDate);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> setBackupEndDate(DateTime? date) {
    // 对结束日期应用相同的逻辑
    if (date == null) {
      return _userSettingDao.deleteSetting(SettingsKeys.backupEndDate);
    } else {
      return _userSettingDao.upsertSetting(
        UserSettingsCompanion(
          key: const Value(SettingsKeys.backupEndDate),
          value: Value(date.toIso8601String()),
        ),
      );
    }
  }
}
