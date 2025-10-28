import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/providers/settings_provider.dart';
import 'package:mobile/services/settings_service.dart';

@RoutePage()
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  // 日期范围选择逻辑
  Future<void> _selectDateRange(
    BuildContext context,
    WidgetRef ref, {
    required DateTime? startDate,
    required DateTime? endDate,
    required void Function(DateTime?, DateTime?) onDateRangeSelected,
  }) async {
    final now = DateTime.now();
    final initialStartDate = startDate ?? now.subtract(const Duration(days: 7));
    final initialEndDate = endDate ?? now;

    // 使用 showDateRangePicker 选择日期范围
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now, // 用户不能选择未来日期
      initialDateRange: DateTimeRange(
        start: initialStartDate,
        end: initialEndDate,
      ),
      locale: const Locale('zh', 'CN'), // 设置中文显示
      helpText: '选择备份日期范围',
      cancelText: '取消',
      confirmText: '确定',
      saveText: '保存',
      errorFormatText: '无效的日期格式',
      errorInvalidText: '无效的日期范围',
      errorInvalidRangeText: '开始日期不能晚于结束日期',
    );

    if (dateRange != null) {
      onDateRangeSelected(dateRange.start, dateRange.end);
    }
  }

  // 格式化日期范围文本
  String _getDateRangeText(
    DateTime? startDate,
    DateTime? endDate,
    DateFormat dateFormat,
  ) {
    if (startDate == null && endDate == null) {
      return '不限制日期范围';
    } else if (startDate != null && endDate != null) {
      return '${dateFormat.format(startDate)} 至 ${dateFormat.format(endDate)}';
    } else if (startDate != null) {
      return '从 ${dateFormat.format(startDate)} 开始';
    } else {
      return '到 ${dateFormat.format(endDate!)} 结束';
    }
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
                    // --- 日期范围选择控件 ---
                    Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        title: const Text(
                          '备份日期范围',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              _getDateRangeText(
                                settingsState.backupStartDate,
                                settingsState.backupEndDate,
                                dateFormat,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    settingsState.backupStartDate != null ||
                                        settingsState.backupEndDate != null
                                    ? theme.colorScheme.primary
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '选择要备份的媒体文件的时间范围',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (settingsState.backupStartDate != null ||
                                settingsState.backupEndDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  settingsNotifier.updateBackupStartDate(null);
                                  settingsNotifier.updateBackupEndDate(null);
                                },
                                tooltip: '清除日期范围',
                                color: theme.colorScheme.error,
                              ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.date_range,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _selectDateRange(
                          context,
                          ref,
                          startDate: settingsState.backupStartDate,
                          endDate: settingsState.backupEndDate,
                          onDateRangeSelected: (startDate, endDate) {
                            settingsNotifier.updateBackupStartDate(startDate);
                            settingsNotifier.updateBackupEndDate(endDate);
                          },
                        ),
                      ),
                    ),
                    // 立即备份按钮
                    ListTile(
                      enabled: !settingsState.isManualBackupRunning,
                      title: Text(
                        '立即备份',
                        style: TextStyle(
                          color: !settingsState.isManualBackupRunning
                              ? null
                              : theme.disabledColor,
                        ),
                      ),
                      subtitle: settingsState.isManualBackupRunning
                          ? const Text('备份进行中...')
                          : const Text('立即备份指定时间段内的媒体资源'),
                      trailing: settingsState.isManualBackupRunning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.backup),
                      onTap: !settingsState.isManualBackupRunning
                          ? () => settingsNotifier.startManualBackup()
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    // 显示备份结果消息
                    if (settingsState.manualBackupMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          color:
                              settingsState.manualBackupMessage!.contains('失败')
                              ? theme.colorScheme.errorContainer
                              : theme.colorScheme.primaryContainer,
                          child: ListTile(
                            title: Text(
                              settingsState.manualBackupMessage!,
                              style: TextStyle(
                                color:
                                    settingsState.manualBackupMessage!.contains(
                                      '失败',
                                    )
                                    ? theme.colorScheme.onErrorContainer
                                    : theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  settingsNotifier.clearBackupMessage(),
                            ),
                          ),
                        ),
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
