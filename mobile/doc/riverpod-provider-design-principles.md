# Riverpod Provider 设计原则指南

> **规范来源**: `openspec/specs/riverpod-provider-design/spec.md`  
> **最后更新**: 2026-01-08

本文档基于项目实践中遇到的问题和解决方案，总结了 Riverpod Provider 的设计原则和最佳实践，旨在避免常见的初始化死锁、条件渲染死锁和状态管理不一致等问题。

## 目录

1. [核心原则](#核心原则)
2. [常见问题与解决方案](#常见问题与解决方案)
3. [代码示例](#代码示例)
4. [迁移指南](#迁移指南)

## 核心原则

### 原则 1: build() 方法必须负责数据加载

**规则**: Provider 的 `build()` 方法必须直接加载数据，而不是返回占位值（空列表、null 等）。

**原因**:
- 符合 Riverpod 的设计理念：`build()` 负责初始化
- 避免时序竞争：不需要手动调用 `load()`
- 简化状态管理：减少状态转换的复杂度

**正确示例**:
```dart
@riverpod
class GroupFeedProvider extends _$GroupFeedProvider {
  @override
  Future<List<Post>> build(String groupUuid) async {
    // ✅ 正确：在 build() 中直接加载数据
    final service = ref.read(postServiceProvider);
    final posts = await service.getGroupFeed(
      groupUuid: groupUuid,
      page: 1,
      limit: 20,
    );
    return posts;
  }
}
```

**错误示例**:
```dart
@riverpod
class GroupFeedProvider extends _$GroupFeedProvider {
  @override
  Future<List<Post>> build(String groupUuid) async {
    // ❌ 错误：返回占位值，依赖手动调用 load()
    return [];
  }
  
  Future<void> load() async {
    // 手动加载数据...
  }
}
```

### 原则 2: 在顶层无条件 watch Provider

**规则**: 所有需要的 Provider 必须在 Widget 的 `build()` 方法顶层无条件 watch，避免在条件渲染中 watch。

**原因**:
- 确保 Provider 能够及时初始化
- 避免条件渲染导致的依赖链断裂
- 实现并行加载，提升性能

**正确示例**:
```dart
class GroupDetailPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 正确：在顶层无条件 watch 所有需要的 Provider
    final detailAsync = ref.watch(groupDetailProviderProvider(groupUuid));
    ref.watch(groupFeedProviderProvider(groupUuid)); // 确保初始化
    
    return Scaffold(
      body: detailAsync.when(
        data: (detail) => _buildContent(context, detail),
        loading: () => CircularProgressIndicator(),
        error: (error, _) => ErrorWidget(error),
      ),
    );
  }
}
```

**错误示例**:
```dart
class GroupDetailPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(groupDetailProviderProvider(groupUuid));
    
    return Scaffold(
      body: detailAsync.when(
        data: (detail) {
          // ❌ 错误：在条件渲染中 watch Provider
          final feedAsync = ref.watch(groupFeedProviderProvider(groupUuid));
          return _buildContent(context, detail, feedAsync);
        },
        // ...
      ),
    );
  }
}
```

### 原则 3: 并行加载策略

**规则**: 多个 Provider 应该在顶层并行 watch，实现并行加载。

**原因**:
- 提升性能：多个 Provider 可以同时加载数据
- 减少等待时间：不等待一个 Provider 完成再加载另一个

**正确示例**:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✅ 正确：并行 watch 多个 Provider
  final detailAsync = ref.watch(groupDetailProviderProvider(groupUuid));
  final feedAsync = ref.watch(groupFeedProviderProvider(groupUuid));
  final membersAsync = ref.watch(groupMembersProviderProvider(groupUuid));
  
  // 所有 Provider 同时开始加载
  // ...
}
```

**错误示例**:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final detailAsync = ref.watch(groupDetailProviderProvider(groupUuid));
  
  return detailAsync.when(
    data: (detail) {
      // ❌ 错误：串行加载，等待 detail 完成才加载 feed
      final feedAsync = ref.watch(groupFeedProviderProvider(groupUuid));
      return _buildContent(detail, feedAsync);
    },
    // ...
  );
}
```

### 原则 4: 统一的错误处理策略

**规则**: Provider 的 `build()` 方法在加载失败时应该抛出异常，而不是返回占位值。

**原因**:
- 让 UI 能够正确显示错误状态
- 避免 UI 一直显示加载中（当返回 null 时）
- 提供清晰的错误信息

**正确示例**:
```dart
@override
Future<GroupDetail?> build(String groupUuid) async {
  try {
    final service = ref.read(groupServiceProvider);
    final details = await service.getGroupDetails(groupUuid);
    return details;
  } catch (e, stackTrace) {
    // ✅ 正确：抛出异常，让 Riverpod 处理错误状态
    throw e; // 或者使用 rethrow
  }
}
```

**错误示例**:
```dart
@override
Future<GroupDetail?> build(String groupUuid) async {
  try {
    final service = ref.read(groupServiceProvider);
    final details = await service.getGroupDetails(groupUuid);
    return details;
  } catch (e, stackTrace) {
    // ❌ 错误：返回 null，UI 无法区分"加载中"和"加载失败"
    return null;
  }
}
```

### 原则 5: 状态管理一致性

**规则**: 所有 Provider 必须遵循相同的设计模式和错误处理策略。

**原因**:
- 提高代码可维护性
- 减少认知负担
- 避免不同 Provider 行为不一致导致的问题

## 常见问题与解决方案

### 问题 1: 初始化死锁

**症状**: Provider 的 `build()` 返回占位值，手动调用 `load()` 时被跳过。

**原因**: 时序竞争问题。`build()` 返回 `Future.value([])` 时，Riverpod 会先进入 `loading` 状态，然后才变为 `hasValue`。如果在 `build()` 完成前调用 `load()`，状态仍是 `loading`，导致 `load()` 被跳过。

**解决方案**: 在 `build()` 中直接加载数据，而不是返回占位值。

### 问题 2: 条件渲染死锁

**症状**: Provider 在条件渲染的 Widget 中被 watch，导致初始化被延迟或跳过。

**原因**: Riverpod 的懒加载机制。Provider 只有在被 `watch` 或 `read` 时才会初始化。如果 Provider 在条件渲染的 Widget 中被 watch，而条件不满足，Provider 永远不会初始化。

**解决方案**: 在 Widget 的 `build()` 方法顶层无条件 watch 所有需要的 Provider。

### 问题 3: 状态管理不一致

**症状**: 不同 Provider 采用不同的初始化策略，导致行为不一致。

**原因**: 缺乏统一的设计规范。

**解决方案**: 所有 Provider 遵循相同的设计模式（在 `build()` 中直接加载数据）。

## 代码示例

### 完整的 Provider 示例

```dart
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/providers/post/post_providers.dart';

part 'group_feed_provider.g.dart';

/// 圈子 Feed 流 Provider
/// 使用 family 参数区分不同的圈子，管理 Feed 流状态（内存中）
@riverpod
class GroupFeedProvider extends _$GroupFeedProvider {
  final Logger _log = Logger('GroupFeedProvider');

  @override
  Future<List<Post>> build(String groupUuid) async {
    _log.info('[GroupFeedProvider] build() called for groupUuid: $groupUuid');
    
    // ✅ 在 build() 中直接加载数据
    try {
      _log.info('[GroupFeedProvider] Loading feed in build()');
      final service = ref.read(postServiceProvider);
      final posts = await service.getGroupFeed(
        groupUuid: groupUuid,
        page: 1,
        limit: 20,
      );
      _log.info('[GroupFeedProvider] Feed loaded in build(): ${posts.length} posts');
      return posts;
    } catch (e, stackTrace) {
      _log.severe('[GroupFeedProvider] Error loading feed in build(): $e', e, stackTrace);
      // ✅ 抛出异常，让 Riverpod 处理错误状态
      rethrow;
    }
  }

  /// 刷新 Feed 流（重新加载第一页）
  /// 注意：此方法用于手动刷新，不用于初始化
  Future<void> refresh() async {
    if (state.isLoading) return; // 防止重复加载

    state = const AsyncValue.loading();
    try {
      final service = ref.read(postServiceProvider);
      final posts = await service.getGroupFeed(
        groupUuid: groupUuid,
        page: 1,
        limit: 20,
      );
      state = AsyncValue.data(posts);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
```

### 完整的 Widget 示例

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/providers/group/group_detail_provider.dart';
import 'package:prismbox/providers/post/group_feed_provider.dart';

class GroupDetailPage extends ConsumerWidget {
  final String groupUuid;

  const GroupDetailPage({required this.groupUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 在顶层无条件 watch 所有需要的 Provider
    final detailAsync = ref.watch(groupDetailProviderProvider(groupUuid));
    ref.watch(groupFeedProviderProvider(groupUuid)); // 确保初始化
    
    return Scaffold(
      appBar: AppBar(
        title: detailAsync.when(
          data: (detail) => Text(detail?.name ?? '圈子详情'),
          loading: () => const Text('圈子详情'),
          error: (_, __) => const Text('圈子详情'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 刷新所有 Provider
          await Future.wait([
            ref.read(groupDetailProviderProvider(groupUuid).notifier).refresh(),
            ref.read(groupFeedProviderProvider(groupUuid).notifier).refresh(),
          ]);
        },
        child: detailAsync.when(
          data: (detail) {
            if (detail == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildContent(context, ref, detail);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _buildErrorState(context, error),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, detail) {
    // ✅ 在子组件中 watch Provider（此时 Provider 已经初始化）
    final feedAsync = ref.watch(groupFeedProviderProvider(groupUuid));
    
    return CustomScrollView(
      slivers: [
        // 圈子信息卡片
        SliverToBoxAdapter(
          child: GroupInfoCard(groupDetail: detail),
        ),
        // Feed 流
        feedAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('暂无帖子'),
                  ),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => PostCard(post: posts[index]),
                childCount: posts.length,
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (error, stackTrace) => SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  Text('加载 Feed 流失败'),
                  TextButton(
                    onPressed: () {
                      ref.read(groupFeedProviderProvider(groupUuid).notifier).refresh();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('加载失败', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(error.toString(), style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
```

## 迁移指南

### 迁移步骤

1. **识别需要迁移的 Provider**
   - 查找所有 `build()` 方法返回占位值的 Provider
   - 查找所有依赖手动调用 `load()` 进行初始化的 Provider

2. **修改 build() 方法**
   - 将数据加载逻辑从 `load()` 方法移动到 `build()` 方法
   - 确保错误处理策略统一（抛出异常）

3. **修改 Widget 代码**
   - 将 Provider 的 watch 从条件渲染中移到顶层
   - 确保所有需要的 Provider 在顶层无条件 watch

4. **测试验证**
   - 验证 Provider 能够正常初始化
   - 验证错误状态能够正确显示
   - 验证刷新功能正常工作

### 迁移示例

**迁移前**:
```dart
// Provider
@override
Future<List<Post>> build(String groupUuid) async {
  return []; // 返回占位值
}

Future<void> load() async {
  state = const AsyncValue.loading();
  final posts = await service.getGroupFeed(...);
  state = AsyncValue.data(posts);
}

// Widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final detailAsync = ref.watch(groupDetailProviderProvider(...));
  
  return detailAsync.when(
    data: (detail) {
      // 在条件渲染中 watch
      final feedAsync = ref.watch(groupFeedProviderProvider(...));
      ref.read(groupFeedProviderProvider(...).notifier).load(); // 手动调用
      return _buildContent(detail, feedAsync);
    },
    // ...
  );
}
```

**迁移后**:
```dart
// Provider
@override
Future<List<Post>> build(String groupUuid) async {
  // ✅ 在 build() 中直接加载数据
  final service = ref.read(postServiceProvider);
  final posts = await service.getGroupFeed(
    groupUuid: groupUuid,
    page: 1,
    limit: 20,
  );
  return posts;
}

Future<void> refresh() async {
  // ✅ refresh() 仅用于手动刷新
  // ...
}

// Widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✅ 在顶层无条件 watch
  final detailAsync = ref.watch(groupDetailProviderProvider(...));
  ref.watch(groupFeedProviderProvider(...)); // 确保初始化
  
  return detailAsync.when(
    data: (detail) {
      // ✅ Provider 已经初始化，可以直接使用
      final feedAsync = ref.watch(groupFeedProviderProvider(...));
      return _buildContent(detail, feedAsync);
    },
    // ...
  );
}
```

## 参考资源

- [Riverpod 官方文档](https://riverpod.dev/)
- [项目 OpenSpec 规范](../openspec/specs/riverpod-provider-design/spec.md)
- [Riverpod AsyncNotifier 最佳实践](./riverpod-asyncnotifier-best-practices.md)

## 总结

遵循这些设计原则可以：
- ✅ 避免初始化死锁和条件渲染死锁
- ✅ 实现并行加载，提升性能
- ✅ 确保状态管理的一致性和可维护性
- ✅ 提供清晰的错误处理策略

**记住**: 新代码必须遵循这些原则，现有代码可以逐步迁移。

