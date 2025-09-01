// lib/ui/group/pages/group_feed_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/providers/group_providers.dart';
// import 'package:mobile/providers/providers.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/ui/group/pages/new_thread_sheet.dart';
import 'package:mobile/ui/group/viewmodels/group_feed_state.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_widget.dart';
// import 'package:wechat_assets_picker/wechat_assets_picker.dart';

@RoutePage()
class GroupFeedPage extends ConsumerStatefulWidget {
  final String uuid;
  const GroupFeedPage({super.key, @PathParam('uuid') required this.uuid});

  @override
  ConsumerState<GroupFeedPage> createState() => _GroupFeedPageState();
}

class _GroupFeedPageState extends ConsumerState<GroupFeedPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isUiVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _isUiVisible) {
      setState(() {
        _isUiVisible = false;
      });
    } else if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        !_isUiVisible) {
      setState(() {
        _isUiVisible = true;
      });
    }

    final notifier = ref.read(groupFeedViewModelProvider(widget.uuid).notifier);
    final state = ref.read(groupFeedViewModelProvider(widget.uuid));

    if (!state.isLoadingNextPage &&
        !state.hasReachedMax &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      notifier.fetchNextPage();
    }
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          child: NewThreadSheet(groupId: widget.uuid),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(groupFeedViewModelProvider(widget.uuid));
    final groupDetailsAsync = ref.watch(groupDetailsProvider(widget.uuid));

    final appBar = AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      title: groupDetailsAsync.when(
        data: (group) => Text(group.name, overflow: TextOverflow.ellipsis),
        loading: () => const Text('Group Feed'),
        error: (e, s) => const Text('Group Feed'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.people_alt_outlined),
          tooltip: 'Members',
          onPressed: () {
            AutoRouter.of(context).push(GroupMembersRoute(uuid: widget.uuid));
          },
        ),
        groupDetailsAsync.when(
          data: (group) {
            final bool isOwnerOrAdmin =
                group.currentUserRole == GroupRole.owner ||
                group.currentUserRole == GroupRole.admin;
            if (isOwnerOrAdmin) {
              return IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  AutoRouter.of(
                    context,
                  ).push(GroupSettingsRoute(uuid: widget.uuid));
                },
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
        ),
      ],
    );

    // --- 1. 这是关键的修正 ---
    // 获取状态栏的高度
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    // 计算 AppBar 的总高度 = 工具栏高度 + 状态栏高度
    final double totalAppBarHeight =
        appBar.preferredSize.height + statusBarHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // --- 2. 将修正后的总高度用于列表的顶部 padding ---
          _buildFeedContent(feedState, totalAppBarHeight),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            // --- 3. 将修正后的总高度用于动画的移动距离 ---
            top: _isUiVisible ? 0 : -totalAppBarHeight,
            left: 0,
            right: 0,
            child: appBar,
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(child: child, scale: animation);
        },
        child: _isUiVisible
            ? FloatingActionButton(
                key: const ValueKey('fab_visible'),
                onPressed: _showCreatePostSheet,
                tooltip: 'Create a new post',
                shape: const CircleBorder(),
                elevation: 8.0,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : const SizedBox.shrink(key: ValueKey('fab_hidden')),
      ),
    );
  }

  Widget _buildFeedContent(GroupFeedState feedState, double topPadding) {
    if (feedState.isLoading && feedState.feedItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feedState.errorMessage != null && feedState.feedItems.isEmpty) {
      return Center(
        child: Text('Failed to load feed: ${feedState.errorMessage}'),
      );
    }

    if (feedState.feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nothing in this group yet.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreatePostSheet,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Share the first post'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(groupFeedViewModelProvider(widget.uuid).notifier).refresh(),
      child: ListView.builder(
        padding: EdgeInsets.only(top: topPadding),
        controller: _scrollController,
        itemCount:
            feedState.feedItems.length + (feedState.isLoadingNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == feedState.feedItems.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = feedState.feedItems[index];
          return PostWidget(item: item);
        },
      ),
    );
  }
}
