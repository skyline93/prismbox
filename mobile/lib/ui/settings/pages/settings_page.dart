import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/providers/settings_provider.dart';
import 'package:mobile/services/settings_service.dart';

@RoutePage()
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  // 提取日期选择逻辑为一个辅助方法
  Future<void> _selectDate(
    BuildContext context,
    WidgetRef ref, {
    required DateTime? initialDate,
    required void Function(DateTime?) onDateSelected,
  }) async {
    final now = DateTime.now();
    // showDatePicker 返回的是 Future<DateTime?>
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now, // 用户不能选择未来日期
    );

    // 用户可能点击了取消，此时 newDate 为 null
    // 我们需要处理这种情况，但这里的逻辑是直接将结果（无论是日期还是null）传递给 view model
    onDateSelected(newDate);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final isBackupEnabled = settingsState.isAutoBackupEnabled;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(title: const Text('应用设置'), centerTitle: true),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _SettingsGroup(
                  title: '传输设置',
                  children: [
                    _SliderListTile(
                      title: '最大上传并发数',
                      value: settingsState.maxConcurrentUploads,
                      onChanged: (newValue) {
                        settingsNotifier.updateMaxConcurrentUploads(newValue);
                      },
                    ),
                    _SliderListTile(
                      title: '最大下载并发数',
                      value: settingsState.maxConcurrentDownloads,
                      onChanged: (newValue) {
                        settingsNotifier.updateMaxConcurrentDownloads(newValue);
                      },
                    ),
                  ],
                ),
                _SettingsGroup(
                  title: '备份设置',
                  children: [
                    SwitchListTile(
                      title: const Text('自动备份'),
                      subtitle: const Text('自动备份相册中的新照片和视频'),
                      value: settingsState.isAutoBackupEnabled,
                      onChanged: (newValue) {
                        settingsNotifier.updateAutoBackupEnabled(newValue);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    ListTile(
                      enabled: isBackupEnabled,
                      title: Text(
                        '备份频率',
                        style: TextStyle(
                          color: isBackupEnabled ? null : theme.disabledColor,
                        ),
                      ),
                      trailing: DropdownButton<BackupFrequency>(
                        value: settingsState.backupFrequency,
                        onChanged: isBackupEnabled
                            ? (BackupFrequency? newValue) {
                                if (newValue != null) {
                                  settingsNotifier.updateBackupFrequency(
                                    newValue,
                                  );
                                }
                              }
                            : null,
                        items: const [
                          DropdownMenuItem(
                            value: BackupFrequency.minutes,
                            child: Text('每15分钟'),
                          ),
                          DropdownMenuItem(
                            value: BackupFrequency.hours,
                            child: Text('每小时'),
                          ),
                          DropdownMenuItem(
                            value: BackupFrequency.daily,
                            child: Text('每天'),
                          ),
                          DropdownMenuItem(
                            value: BackupFrequency.weekly,
                            child: Text('每周'),
                          ),
                        ],
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('仅在Wi-Fi下备份'),
                      subtitle: const Text('为节省流量，仅在连接Wi-Fi时执行备份'),
                      value: settingsState.isBackupOnWifiOnly,
                      onChanged: isBackupEnabled
                          ? (newValue) {
                              settingsNotifier.updateBackupOnWifiOnly(newValue);
                            }
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    // --- 新增UI控件 ---
                    ListTile(
                      enabled: isBackupEnabled,
                      title: Text(
                        '备份开始日期',
                        style: TextStyle(
                          color: isBackupEnabled ? null : theme.disabledColor,
                        ),
                      ),
                      subtitle: Text(
                        settingsState.backupStartDate != null
                            ? dateFormat.format(settingsState.backupStartDate!)
                            : '不限制',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: isBackupEnabled
                          ? () => _selectDate(
                              context,
                              ref,
                              initialDate: settingsState.backupStartDate,
                              onDateSelected: (date) =>
                                  settingsNotifier.updateBackupStartDate(date),
                            )
                          : null,
                    ),
                    ListTile(
                      enabled: isBackupEnabled,
                      title: Text(
                        '备份结束日期',
                        style: TextStyle(
                          color: isBackupEnabled ? null : theme.disabledColor,
                        ),
                      ),
                      subtitle: Text(
                        settingsState.backupEndDate != null
                            ? dateFormat.format(settingsState.backupEndDate!)
                            : '不限制',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: isBackupEnabled
                          ? () => _selectDate(
                              context,
                              ref,
                              initialDate: settingsState.backupEndDate,
                              onDateSelected: (date) =>
                                  settingsNotifier.updateBackupEndDate(date),
                            )
                          : null,
                    ),
                  ],
                ),
                _SettingsGroup(
                  title: '其他',
                  children: [
                    ListTile(
                      title: const Text('清除缓存'),
                      subtitle: const Text('清除本地的图片和视频缓存'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('缓存已清除 (功能待实现)'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SliderListTile extends StatelessWidget {
  final String title;
  final int value;
  final ValueChanged<int> onChanged;

  const _SliderListTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toString(),
            onChanged: (double newValue) {
              onChanged(newValue.round());
            },
          ),
        ],
      ),
    );
  }
}
