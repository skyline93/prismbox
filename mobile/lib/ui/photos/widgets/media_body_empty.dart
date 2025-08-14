import 'package:flutter/material.dart';

class EmptyMediaView extends StatelessWidget {
  final VoidCallback onSync;

  const EmptyMediaView({super.key, required this.onSync});

  @override
  Widget build(BuildContext context) {
    // 使用 LayoutBuilder 和 SingleChildScrollView 确保即使在内容为空时，
    // 用户仍然可以下拉以触发 RefreshIndicator。
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '相册为空',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '下拉以从云端同步',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: onSync,
                      icon: const Icon(Icons.sync),
                      label: const Text('立即同步'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
