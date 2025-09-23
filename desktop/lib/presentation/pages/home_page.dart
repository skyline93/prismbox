import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/datasources/local/app_database.dart';
import '../providers/providers.dart';
import '../widgets/photo_grid_item.dart';
import '../widgets/transfer_status_panel.dart';

@RoutePage()
class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAssetsAsync = ref.watch(mediaAssetsStreamProvider);
    final homeViewModel = ref.read(homeViewModelProvider.notifier);

    // --- 新增状态管理 ---
    // 使用 Set 存储选中的资源，效率更高
    final selectedAssets = useState<Set<MediaAsset>>({});
    // 跟踪是否处于选择模式
    final isSelectionMode = useState(false);

    // --- 新增辅助方法 ---
    // 切换单个资源的选择状态
    void toggleSelection(MediaAsset asset) {
      final newSelectedAssets = Set<MediaAsset>.from(selectedAssets.value);
      if (newSelectedAssets.contains(asset)) {
        newSelectedAssets.remove(asset);
      } else {
        newSelectedAssets.add(asset);
      }
      selectedAssets.value = newSelectedAssets;

      // 如果所有项目都被取消选择，则自动退出选择模式
      if (selectedAssets.value.isEmpty) {
        isSelectionMode.value = false;
      }
    }

    // 取消并退出选择模式
    void cancelSelection() {
      selectedAssets.value = {};
      isSelectionMode.value = false;
    }

    useEffect(() {
      Future.microtask(() => homeViewModel.syncMedia());
      return null;
    }, const []);

    return Scaffold(
      appBar: isSelectionMode.value
          // --- 选择模式下的 AppBar ---
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
                onPressed: cancelSelection,
              ),
              title: Text('${selectedAssets.value.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Download Selected',
                  // 如果没有选中任何内容，则禁用按钮
                  onPressed: selectedAssets.value.isEmpty
                      ? null
                      : () async {
                          final String? outputDirectory = await FilePicker
                              .platform
                              .getDirectoryPath();
                          if (outputDirectory != null) {
                            // 使用选中的资源列表进行下载
                            homeViewModel.startDownloads(
                              selectedAssets.value.toList(),
                              outputDirectory,
                            );
                            // 下载开始后退出选择模式
                            cancelSelection();
                          }
                        },
                ),
              ],
            )
          // --- 正常模式下的 AppBar ---
          : AppBar(
              title: const Text('My Cloud Photos'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.upload),
                  tooltip: 'Upload Files',
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                    );
                    if (result != null) {
                      final files = result.paths
                          .map((path) => File(path!))
                          .toList();
                      homeViewModel.startUploads(files);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Sync with Cloud',
                  onPressed: homeViewModel.syncMedia,
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () =>
                      ref.read(authViewModelProvider.notifier).logout(),
                ),
              ],
            ),
      body: Column(
        children: [
          Expanded(
            child: mediaAssetsAsync.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return const Center(
                    child: Text('No photos yet. Try uploading some!'),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 2, // Changed from 8 to 4
                    mainAxisSpacing: 2, // Changed from 8 to 4
                  ),
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    final isSelected = selectedAssets.value.contains(asset);
                    return PhotoGridItem(
                      asset: asset,
                      isSelected: isSelected, // 传递选中状态
                      onTap: () {
                        // 如果在选择模式下，点按是用来选择或取消选择
                        if (isSelectionMode.value) {
                          toggleSelection(asset);
                        } else {
                          // 正常模式下，可以跳转到详情页（此处暂不实现）
                        }
                      },
                      onLongPress: () {
                        // 长按总是用于进入选择模式并选中当前项
                        if (!isSelectionMode.value) {
                          isSelectionMode.value = true;
                          toggleSelection(asset);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          const TransferStatusPanel(),
        ],
      ),
    );
  }
}
