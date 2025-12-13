// lib/services/backup/backup_config_validator.dart

import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/auto_backup_mode.dart';

/// 配置验证结果
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });
}

/// 配置验证器
class BackupConfigValidator {
  /// 验证备份配置
  Future<ValidationResult> validate(AppDatabase database, String userId) async {
    final config = await (database.select(database.backupStatusEntity)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
    
    if (config == null) {
      return ValidationResult(
        isValid: false,
        errors: ['备份配置不存在'],
      );
    }
    final errors = <String>[];

    // 验证时间范围
    if (config.autoBackupMode == AutoBackupMode.timeRange) {
      if (config.timeRangeStart == null || config.timeRangeEnd == null) {
        errors.add('时间范围模式必须设置起始和结束时间');
      } else if (config.timeRangeStart!.isAfter(config.timeRangeEnd!)) {
        errors.add('起始时间不能晚于结束时间');
      } else if (config.timeRangeEnd!
              .difference(config.timeRangeStart!)
              .inDays >
          365) {
        errors.add('时间范围不能超过 365 天');
      }
    }

    // 验证相册选择
    if (config.autoBackupMode == AutoBackupMode.selectedAlbums) {
      // 注意：这里无法直接验证相册是否选择，需要在业务层验证
      // 可以添加一个辅助方法检查相册选择
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

