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
    // 浮动按钮的显示/隐藏逻辑
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

    // 分页加载逻辑
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(groupFeedViewModelProvider(widget.uuid).notifier)
            .refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              pinned: true,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              toolbarHeight: 30.0,
              expandedHeight: 60.0,
              scrolledUnderElevation: 6.0,
              shadowColor: Colors.black12,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // FIX 1: 'pop' is deprecated. Use 'maybePop'.
                        BackButton(
                          onPressed: () => AutoRouter.of(context).maybePop(),
                        ),

                        Expanded(
                          child: groupDetailsAsync.when(
                            data: (group) => Text(
                              group.name,
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(fontSize: 18.0),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            // FIX 2: The argument type 'SizedBox' can't be assigned to the parameter type 'Widget Function()'.
                            loading: () => const SizedBox.shrink(),
                            error: (e, s) => const SizedBox.shrink(),
                          ),
                        ),

                        groupDetailsAsync.when(
                          data: (group) {
                            final bool isOwnerOrAdmin =
                                group.currentUserRole == GroupRole.owner ||
                                group.currentUserRole == GroupRole.admin;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.people_alt_outlined),
                                  tooltip: 'Members',
                                  onPressed: () {
                                    AutoRouter.of(context).push(
                                      GroupMembersRoute(uuid: widget.uuid),
                                    );
                                  },
                                ),
                                if (isOwnerOrAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.settings),
                                    tooltip: 'Settings',
                                    onPressed: () {
                                      AutoRouter.of(context).push(
                                        GroupSettingsRoute(uuid: widget.uuid),
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                          // FIX 2: (Same as above)
                          loading: () => const SizedBox.shrink(),
                          error: (e, s) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildSliverContent(feedState),
          ],
        ),
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

  Widget _buildSliverContent(GroupFeedState feedState) {
    if (feedState.isLoading && feedState.feedItems.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (feedState.errorMessage != null && feedState.feedItems.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text('Failed to load feed: ${feedState.errorMessage}'),
        ),
      );
    }

    if (feedState.feedItems.isEmpty) {
      // FIX 4: The 'child' argument should be last in widget constructor invocations.
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
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
        ),
      );
    }

    return SliverList.builder(
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
        return PostWidget(groupUuid: widget.uuid, item: item);
      },
    );
  }
}
