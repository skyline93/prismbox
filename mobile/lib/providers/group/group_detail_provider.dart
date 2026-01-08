// lib/providers/group/group_detail_provider.dart
//
// 设计原则参考：
// - OpenSpec: openspec/specs/riverpod-provider-design/spec.md
// - 设计指南: mobile/doc/riverpod-provider-design-principles.md

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/models/group/group_detail.dart' as models;
import 'package:prismbox/providers/group/group_list_provider.dart';

part 'group_detail_provider.g.dart';

/// 圈子详情 Provider
/// 使用 family 参数区分不同的圈子
/// 
/// 设计原则：
/// - build() 方法直接加载数据，不返回占位值
/// - 错误时抛出异常，让 Riverpod 处理错误状态
@riverpod
class GroupDetailProvider extends _$GroupDetailProvider {
  final Logger _log = Logger('GroupDetailProvider');

  @override
  Future<models.GroupDetail?> build(String groupUuid) async {
    _log.info('[GroupDetailProvider] build() called for groupUuid: $groupUuid');
    
    // 在 build() 中直接加载数据，而不是返回 null
    // 这样可以避免时序问题，确保数据被正确加载
    _log.info('[GroupDetailProvider] Loading group detail in build()');
    final service = ref.read(groupServiceProvider);
    final details = await service.getGroupDetails(groupUuid);
    _log.info('[GroupDetailProvider] Group detail loaded in build()');
    return details;
  }

  /// 加载圈子详情
  Future<void> load() async {
    if (state.isLoading) return; // 防止重复加载

    state = const AsyncValue.loading();
    try {
      final service = ref.read(groupServiceProvider);
      final details = await service.getGroupDetails(groupUuid);
      state = AsyncValue.data(details);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 刷新圈子详情
  Future<void> refresh() async {
    await load();
  }
}

