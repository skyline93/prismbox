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
  final DateTime backupStartDate;
  final DateTime backupEndDate;

  BackupSettings({
    required this.isAutoBackupEnabled,
    required this.frequency,
    required this.isBackupOnWifiOnly,
    required this.backupStartDate,
    required this.backupEndDate,
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
    return int.tryParse(value ?? '1') ?? 1;
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
    return int.tryParse(value ?? '2') ?? 2;
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
          BackupFrequency.minutes.name;
      final frequency = BackupFrequency.values.firstWhere(
        (e) => e.name == frequencyString,
        orElse: () => BackupFrequency.minutes,
      );

      final now = DateTime.now();

      final endDateString = settingsMap[SettingsKeys.backupEndDate];
      final storedEndDate = endDateString != null
          ? DateTime.tryParse(endDateString)
          : null;

      final endDate = storedEndDate ?? now;

      final startDateString = settingsMap[SettingsKeys.backupStartDate];
      final storedStartDate = startDateString != null
          ? DateTime.tryParse(startDateString)
          : null;

      final startDate =
          storedStartDate ?? now.subtract(const Duration(days: 3));

      return BackupSettings(
        isAutoBackupEnabled: isEnabled,
        frequency: frequency,
        isBackupOnWifiOnly: isWifiOnly,
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

  Future<DateTime?> getBackupStartDate() async {
    final value = await _userSettingDao.getSetting(
      SettingsKeys.backupStartDate,
    );
    return DateTime.tryParse(value ?? '') ??
        DateTime.now().subtract(const Duration(days: 3));
  }

  Future<void> setBackupStartDate(DateTime? date) {
    if (date == null) {
      return _userSettingDao.deleteSetting(SettingsKeys.backupStartDate);
    } else {
      return _userSettingDao.upsertSetting(
        UserSettingsCompanion(
          key: const Value(SettingsKeys.backupStartDate),
          value: Value(date.toIso8601String()),
        ),
      );
    }
  }

  Future<DateTime?> getBackupEndDate() async {
    final value = await _userSettingDao.getSetting(SettingsKeys.backupEndDate);
    return DateTime.tryParse(value ?? '') ?? DateTime.now();
  }

  Future<void> setBackupEndDate(DateTime? date) {
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
