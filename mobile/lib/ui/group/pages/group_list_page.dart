// lib/ui/group/pages/group_list_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/providers/group_providers.dart';
import 'package:mobile/ui/group/widgets/group_list_item.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

@RoutePage()
class GroupListPage extends ConsumerStatefulWidget {
  const GroupListPage({super.key});

  @override
  ConsumerState<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends ConsumerState<GroupListPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _isFabVisible) {
      setState(() {
        _isFabVisible = false;
      });
    } else if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        !_isFabVisible) {
      setState(() {
        _isFabVisible = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupListAsync = ref.watch(groupListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: groupListAsync.when(
        loading: () => _buildLoadingSkeleton(),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text('加载失败: $err', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(groupListProvider.future),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return GroupListItemWidget(
                      group: group,
                      onTap: () {
                        AutoRouter.of(
                          context,
                        ).push(GroupFeedRoute(uuid: group.uuid));
                      },
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                    .slideX(begin: 0.2, duration: 500.ms, curve: Curves.easeOut)
                    .then(delay: (100 * index).ms);
              },
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12.0),
            ),
          );
        },
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: _isFabVisible
            ? FloatingActionButton(
                key: const ValueKey('fab_visible'),
                onPressed: () {
                  AutoRouter.of(context).push(const CreateGroupRoute());
                },
                tooltip: '创建新圈子',
                shape: const CircleBorder(),
                elevation: 8.0,
                backgroundColor: theme.primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : const SizedBox.shrink(key: ValueKey('fab_hidden')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 80,
            color: theme.primaryColor.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            '探索，从创建第一个圈子开始',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角“+”按钮，开启你的社区之旅。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 28, backgroundColor: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16.0,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(width: 100, height: 12.0, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
        separatorBuilder: (context, index) => const SizedBox(height: 12.0),
      ),
    );
  }
}
