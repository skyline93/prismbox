// lib/presentation/widgets/timeline/scrubber_segment.dart

/// Scrubber 使用的布局段落
///
/// 表示时间线中一个时间段落（对应一个 [TimelineSection]）的起止滚动偏移，
/// 用于 Scrubber 显示月份标签和拖拽跳转。
class ScrubberLayoutSegment {
  /// 该段落在整体滚动内容中的起始偏移（逻辑像素）
  final double startOffset;

  /// 该段落在整体滚动内容中的结束偏移（逻辑像素）
  final double endOffset;

  /// 该段落代表的日期（用于显示标签和吸附）
  final DateTime date;

  const ScrubberLayoutSegment({
    required this.startOffset,
    required this.endOffset,
    required this.date,
  });
}
