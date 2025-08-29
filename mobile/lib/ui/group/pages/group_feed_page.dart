// lib/ui/group/pages/group_feed_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/group_providers.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/ui/group/widgets/group_media_grid_item.dart';
import 'package:mobile/ui/group/viewmodels/group_feed_state.dart';

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GroupFeedState feedState = ref.watch(groupFeedViewModelProvider(widget.uuid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('圈子动态'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '圈子详情与成员',
            onPressed: () {
              AutoRouter.of(context).push(GroupMembersRoute(uuid: widget.uuid));
            },
          ),
        ],
      ),
      // 核心修正：使用 .when(...) 并提供所有必需的参数
      body: feedState.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(child: CircularProgressIndicator()),
        // 修正 1: 使用正确的状态名 'loaded' 替换 'data'
        loaded: (mediaList, hasReachedMax) {
          if (mediaList.isEmpty) {
            return const Center(
              child: Text('圈子内还没有任何分享'),
            );
          }
          // 修正 3: 使用正确的刷新模式
          return RefreshIndicator(
            // `onRefresh` 应该调用 ViewModel 上的一个返回 Future 的方法。
            // 这是处理 StateNotifierProvider 刷新的标准模式。
            // 你需要在你的 GroupFeedViewModel 中添加一个 `refresh` 方法。
            onRefresh: () =>
                ref.read(groupFeedViewModelProvider(widget.uuid).notifier).refresh(),
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
                return GroupMediaGridItem(
                  groupMedia: groupMedia,
                  onTap: () {
                    // TODO: 跳转到大图浏览页
                  },
                );
              },
            ),
          );
        },
        error: (err) => Center(child: Text('加载动态失败: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Sprint M3 任务：实现分享照片流程
        },
        tooltip: '分享照片到圈子',
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }
}
