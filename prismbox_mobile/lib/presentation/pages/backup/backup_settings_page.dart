// lib/presentation/pages/backup/backup_settings_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/auto_backup_mode.dart';
import 'package:prismbox/presentation/widgets/backup/backup_status_widget.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';
import 'package:prismbox/services/backup/backup_service.dart';
import 'package:prismbox/services/backup/backup_config_validator.dart';

/// 备份设置页面
@RoutePage()
class BackupSettingsPage extends ConsumerStatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  ConsumerState<BackupSettingsPage> createState() =>
      _BackupSettingsPageState();
}

class _BackupSettingsPageState extends ConsumerState<BackupSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final authServiceAsync = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('备份设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: authServiceAsync.when(
        data: (authService) => FutureBuilder<String>(
          future: authService.getProfile().then((p) => p.id.toString()),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _BackupSettingsContent(userId: snapshot.data!);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('加载失败: $error'),
        ),
      ),
    );
  }
}

class _BackupSettingsContent extends ConsumerWidget {
  final String userId;

  const _BackupSettingsContent({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupServiceFuture = ref.watch(backupServiceProvider.future);
    final storeService = StoreService();

    return FutureBuilder<BackupService>(
      future: backupServiceFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final backupService = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            children: [
              // 备份状态组件
              const BackupStatusWidget(),

              const Divider(height: 1),

              // 全局自动备份开关
              _GlobalAutoBackupSwitch(storeService: storeService),

              const Divider(height: 1),

              // 网络条件设置
              _NetworkSettingsSection(storeService: storeService),

              const Divider(height: 1),

              // 用户备份配置
              _UserBackupSettingsSection(
                userId: userId,
                backupService: backupService,
                ref: ref,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 全局自动备份开关
class _GlobalAutoBackupSwitch extends ConsumerStatefulWidget {
  final StoreService storeService;

  const _GlobalAutoBackupSwitch({required this.storeService});

  @override
  ConsumerState<_GlobalAutoBackupSwitch> createState() =>
      _GlobalAutoBackupSwitchState();
}

class _GlobalAutoBackupSwitchState
    extends ConsumerState<_GlobalAutoBackupSwitch> {
  bool _autoBackup = false;

  @override
  void initState() {
    super.initState();
    _loadAutoBackup();
  }

  Future<void> _loadAutoBackup() async {
    final value = widget.storeService.get<bool>(
      StoreKey.autoBackup,
      false,
    );
    if (mounted) {
      setState(() {
        _autoBackup = value;
      });
    }
  }

  Future<void> _onChanged(bool value) async {
    await widget.storeService.put(StoreKey.autoBackup, value);
    setState(() {
      _autoBackup = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('全局自动备份'),
      subtitle: const Text('启用后，系统将根据配置自动备份照片'),
      value: _autoBackup,
      onChanged: _onChanged,
    );
  }
}

/// 网络条件设置
class _NetworkSettingsSection extends ConsumerStatefulWidget {
  final StoreService storeService;

  const _NetworkSettingsSection({required this.storeService});

  @override
  ConsumerState<_NetworkSettingsSection> createState() =>
      _NetworkSettingsSectionState();
}

class _NetworkSettingsSectionState
    extends ConsumerState<_NetworkSettingsSection> {
  bool _requireWifi = false;
  bool _requireCharging = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final wifi = widget.storeService.get<bool>(
      StoreKey.backupRequireWifi,
      false,
    );
    final charging = widget.storeService.get<bool>(
      StoreKey.backupRequireCharging,
      false,
    );
    if (mounted) {
      setState(() {
        _requireWifi = wifi;
        _requireCharging = charging;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '网络条件',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SwitchListTile(
          title: const Text('仅 WiFi 上传'),
          subtitle: const Text('仅在 WiFi 网络下执行自动备份'),
          value: _requireWifi,
          onChanged: (value) async {
            await widget.storeService.put(StoreKey.backupRequireWifi, value);
            setState(() {
              _requireWifi = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('充电时备份'),
          subtitle: const Text('仅在设备充电时执行自动备份'),
          value: _requireCharging,
          onChanged: (value) async {
            await widget.storeService.put(
              StoreKey.backupRequireCharging,
              value,
            );
            setState(() {
              _requireCharging = value;
            });
          },
        ),
      ],
    );
  }
}

/// 用户备份配置
class _UserBackupSettingsSection extends ConsumerStatefulWidget {
  final String userId;
  final BackupService backupService;
  final WidgetRef ref;

  const _UserBackupSettingsSection({
    required this.userId,
    required this.backupService,
    required this.ref,
  });

  @override
  ConsumerState<_UserBackupSettingsSection> createState() =>
      _UserBackupSettingsSectionState();
}

class _UserBackupSettingsSectionState
    extends ConsumerState<_UserBackupSettingsSection> {
  bool _enabled = false;
  AutoBackupMode _mode = AutoBackupMode.allUnbacked;
  DateTime? _timeRangeStart;
  DateTime? _timeRangeEnd;

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
  }

  Future<void> _loadBackupStatus() async {
    try {
      final status = await widget.backupService.getBackupStatus(widget.userId);
      if (status != null && mounted) {
        setState(() {
          _enabled = status.enabled;
          _mode = status.mode;
          _timeRangeStart = status.timeRangeStart;
          _timeRangeEnd = status.timeRangeEnd;
        });
      }
    } catch (e) {
      // 忽略错误，使用默认值
    }
  }

  Future<void> _updateBackupConfig() async {
    try {
      // 获取数据库实例
      final database = await widget.ref.read(databaseProvider.future);
      
      // 验证配置
      final validator = BackupConfigValidator();
      final validation = await validator.validate(
        database,
        widget.userId,
      );

      if (!validation.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('配置验证失败: ${validation.errors.join(", ")}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 更新配置（使用 BackupStatusEntityCompanion）
      final companion = BackupStatusEntityCompanion(
        enabled: Value(_enabled),
        autoBackupMode: Value(_mode),
        timeRangeStart: Value(_timeRangeStart),
        timeRangeEnd: Value(_timeRangeEnd),
        updatedAt: Value(DateTime.now()),
      );

      await widget.backupService.updateBackupConfig(
        widget.userId,
        companion,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配置已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '用户备份配置',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SwitchListTile(
          title: const Text('启用自动备份'),
          subtitle: const Text('为该用户启用自动备份功能'),
          value: _enabled,
          onChanged: (value) {
            setState(() {
              _enabled = value;
            });
            _updateBackupConfig();
          },
        ),
        ListTile(
          title: const Text('备份模式'),
          subtitle: Text(_getModeDescription(_mode)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showModeSelector(),
        ),
        if (_mode == AutoBackupMode.timeRange) ...[
          ListTile(
            title: const Text('时间范围起始'),
            subtitle: Text(
              _timeRangeStart?.toString() ?? '未设置',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectTimeRangeStart(),
          ),
          ListTile(
            title: const Text('时间范围结束'),
            subtitle: Text(
              _timeRangeEnd?.toString() ?? '未设置',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectTimeRangeEnd(),
          ),
        ],
        if (_mode == AutoBackupMode.selectedAlbums) ...[
          ListTile(
            title: const Text('选择相册'),
            subtitle: const Text('选择要备份的相册'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 导航到相册选择页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('相册选择功能待实现')),
              );
            },
          ),
        ],
      ],
    );
  }

  String _getModeDescription(AutoBackupMode mode) {
    switch (mode) {
      case AutoBackupMode.allUnbacked:
        return '所有未备份资源';
      case AutoBackupMode.selectedAlbums:
        return '选中相册';
      case AutoBackupMode.timeRange:
        return '时间段';
    }
  }

  Future<void> _showModeSelector() async {
    final selectedMode = await showDialog<AutoBackupMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择备份模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AutoBackupMode>(
              title: const Text('所有未备份资源'),
              value: AutoBackupMode.allUnbacked,
              groupValue: _mode,
              onChanged: (value) {
                Navigator.of(context).pop(value);
              },
            ),
            RadioListTile<AutoBackupMode>(
              title: const Text('选中相册'),
              value: AutoBackupMode.selectedAlbums,
              groupValue: _mode,
              onChanged: (value) {
                Navigator.of(context).pop(value);
              },
            ),
            RadioListTile<AutoBackupMode>(
              title: const Text('时间段'),
              value: AutoBackupMode.timeRange,
              groupValue: _mode,
              onChanged: (value) {
                Navigator.of(context).pop(value);
              },
            ),
          ],
        ),
      ),
    );

    if (selectedMode != null && selectedMode != _mode) {
      setState(() {
        _mode = selectedMode;
        // 切换模式时清空时间范围
        if (selectedMode != AutoBackupMode.timeRange) {
          _timeRangeStart = null;
          _timeRangeEnd = null;
        }
      });
      _updateBackupConfig();
    }
  }

  Future<void> _selectTimeRangeStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timeRangeStart ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _timeRangeStart ?? DateTime.now(),
        ),
      );
      if (time != null) {
        setState(() {
          _timeRangeStart = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
        _updateBackupConfig();
      }
    }
  }

  Future<void> _selectTimeRangeEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timeRangeEnd ?? DateTime.now(),
      firstDate: _timeRangeStart ?? DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _timeRangeEnd ?? DateTime.now(),
        ),
      );
      if (time != null) {
        setState(() {
          _timeRangeEnd = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
        _updateBackupConfig();
      }
    }
  }
}

