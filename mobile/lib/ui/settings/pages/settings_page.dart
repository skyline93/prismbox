import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers/settings_provider.dart';

@RoutePage()
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    // final theme = Theme.of(context);

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
                      subtitle: const Text('当连接到Wi-Fi时自动备份新照片'),
                      value: settingsState.isAutoBackupEnabled,
                      onChanged: (newValue) {
                        settingsNotifier.updateAutoBackupEnabled(newValue);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
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
                        // TODO: Implement cache clearing logic
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

// A helper widget to create grouped sections in the settings list.
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

// A custom widget combining ListTile and Slider for a better UI.
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
