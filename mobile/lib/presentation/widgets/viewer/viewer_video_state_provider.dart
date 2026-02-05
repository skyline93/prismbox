import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前视频资产 ID 的 Provider
///
/// 用于响应式地通知所有 ViewerVideoPage 当前视频状态变化。
/// 当用户在 MediaViewerPage 中切换视频时，该 Provider 的状态会更新，
/// 所有订阅的 ViewerVideoPage 会自动响应状态变化并执行相应的播放逻辑。
///
/// 初始值为 null，表示没有当前视频。
final currentVideoAssetIdProvider = StateProvider<String?>((ref) => null);

/// 当前是否正在播放 Live Photo 关联的短视频
///
/// 用于媒体查看器内「静态主图」与「Live 短视频」视图切换。
/// 与 Immich isPlayingMotionVideoProvider 对齐；页面切换时应重置为 false。
final isPlayingMotionVideoProvider = StateProvider<bool>((ref) => false);

