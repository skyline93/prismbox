// lib/ui/group/viewmodels/group_feed_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
// 导入我们在第一阶段创建的权威实体
import 'package:mobile/domain/entities/group_feed_item_entity.dart';

part 'group_feed_state.freezed.dart';

@freezed
class GroupFeedState with _$GroupFeedState {
  const factory GroupFeedState({
    /// Feed列表数据
    @Default([]) List<GroupFeedItemEntity> feedItems,

    /// 是否正在进行初次加载
    @Default(true) bool isLoading,

    /// 是否正在加载下一页
    @Default(false) bool isLoadingNextPage,

    /// 是否已加载所有数据
    @Default(false) bool hasReachedMax,

    /// 加载过程中发生的错误信息
    String? errorMessage,

    /// 是否正在发布新帖子
    @Default(false) bool isPosting,
    
    @Default(1) int currentPage,

    /// 发布帖子时发生的错误信息
    String? postError,
  }) = _GroupFeedState;
}
