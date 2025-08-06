import 'package:equatable/equatable.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';

/// Timeline 页面的状态模型
///
/// 这是一个不可变的 (immutable) 类，用于封装所有与时间线 UI 相关的数据。
/// 当 ViewModel 需要更新 UI 时，它会创建一个新的 `TimelineState` 实例，而不是修改旧的实例。
/// 这与 Riverpod 和函数式编程的理念相符。
class TimelineState extends Equatable {
  /// 是否处于初始加载状态。
  final bool isLoading;

  /// 显示在 UI 上的媒体实体列表。
  final List<UnifiedMediaEntity> media;

  /// 如果发生错误，则存储错误信息。
  final String? error;

  const TimelineState({
    this.isLoading = true,
    this.media = const [],
    this.error,
  });

  /// 一个工厂构造函数，用于创建初始状态。
  factory TimelineState.initial() {
    return const TimelineState(isLoading: true, media: [], error: null);
  }

  /// 创建状态副本的方法。
  ///
  /// 这是实现状态不可变性的关键。当需要更新状态时，我们调用此方法
  /// 并只传入需要改变的字段，未传入的字段将保持原样。
  TimelineState copyWith({
    bool? isLoading,
    List<UnifiedMediaEntity>? media,
    String? error,
  }) {
    return TimelineState(
      isLoading: isLoading ?? this.isLoading,
      media: media ?? this.media,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isLoading, media, error];
}
