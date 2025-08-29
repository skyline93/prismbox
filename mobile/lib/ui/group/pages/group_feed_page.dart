import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/group_providers.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/ui/group/widgets/group_media_grid_item.dart';
import 'package:mobile/ui/group/viewmodels/group_feed_state.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

@RoutePage()
class GroupFeedPage extends ConsumerStatefulWidget {
  final String uuid;
  const GroupFeedPage({super.key, @PathParam('uuid') required this.uuid});

  @override
  ConsumerState<GroupFeedPage> createState() => _GroupFeedPageState();
}

class _GroupFeedPageState extends ConsumerState<GroupFeedPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(groupFeedViewModelProvider(widget.uuid).notifier)
          .fetchNextPage();
    }
  }

  Future<void> _sharePhotos() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('需要相册访问权限才能分享照片')));
      return;
    }

    if (!mounted) return;
    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 9,
        requestType: RequestType.common,
      ),
    );

    if (assets == null || assets.isEmpty) {
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final mediaRepository = ref.read(mediaRepositoryProvider);
      final List<String> uuids = await mediaRepository.uploadAssets(assets);

      if (uuids.isEmpty) {
        throw Exception("文件上传失败，未能获取UUID");
      }

      final groupRepository = ref.read(groupRepositoryProvider);
      await groupRepository.shareMediaToGroup(widget.uuid, mediaUuids: uuids);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('成功分享到圈子！')));
      await ref
          .read(groupFeedViewModelProvider(widget.uuid).notifier)
          .refresh();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GroupFeedState feedState = ref.watch(
      groupFeedViewModelProvider(widget.uuid),
    );
    // M4: 监视圈子详情以获取角色信息
    final groupDetailsAsync = ref.watch(groupDetailsProvider(widget.uuid));

    return Scaffold(
      appBar: AppBar(
        title: groupDetailsAsync.when(
          data: (group) => Text(group.name, overflow: TextOverflow.ellipsis),
          loading: () => const Text('圈子动态'),
          error: (e, s) => const Text('圈子动态'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: '圈子成员',
            onPressed: () {
              AutoRouter.of(context).push(GroupMembersRoute(uuid: widget.uuid));
            },
          ),
          // M4: 根据权限动态显示设置按钮
          groupDetailsAsync.when(
            data: (group) {
              // 假设 GroupModel 包含一个 `currentUserRole` 字段，类型为 GroupRole (enum)
              final bool isOwnerOrAdmin =
                  group.currentUserRole == GroupRole.owner ||
                  group.currentUserRole == GroupRole.admin;
              if (isOwnerOrAdmin) {
                return IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: '圈子设置',
                  onPressed: () {
                    AutoRouter.of(
                      context,
                    ).push(GroupSettingsRoute(uuid: widget.uuid));
                  },
                );
              }
              return const SizedBox.shrink(); // 不是管理员则不显示
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: feedState.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (mediaList, hasReachedMax) {
          if (mediaList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('圈子内还没有任何分享'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _sharePhotos,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('立即分享第一张'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref
                .read(groupFeedViewModelProvider(widget.uuid).notifier)
                .refresh(),
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(2.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 2.0,
                mainAxisSpacing: 2.0,
              ),
              itemCount: mediaList.length,
              itemBuilder: (context, index) {
                final groupMedia = mediaList[index];
                return GroupMediaGridItem(groupMedia: groupMedia);
              },
            ),
          );
        },
        error: (err) => Center(child: Text('加载动态失败: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sharePhotos,
        tooltip: '分享照片到圈子',
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }
}
