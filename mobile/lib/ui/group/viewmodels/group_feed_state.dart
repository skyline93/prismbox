// lib/ui/group/viewmodels/group_feed_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/data/models/group/group_models.dart';

part 'group_feed_state.freezed.dart';

@freezed
class GroupFeedState with _$GroupFeedState {
  // 初始状态
  const factory GroupFeedState.initial() = _Initial;

  // 加载中状态
  const factory GroupFeedState.loading() = _Loading;

  // 加载成功状态
  const factory GroupFeedState.loaded({
    required List<GroupMediaModel> mediaItems,
    @Default(false) bool hasReachedMax, // 是否已加载全部数据
  }) = _Loaded;

  // 加载失败状态
  const factory GroupFeedState.error(String message) = _Error;
}
