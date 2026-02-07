// lib/presentation/widgets/timeline/scrubber_segment_builder.dart

import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/presentation/widgets/timeline/scrubber_segment.dart';

/// 从 [TimelineSection] 列表估算每个段落的高度并生成 [ScrubberLayoutSegment] 列表。
///
/// 估算规则与 [TimelineSectionHeader]、[SelectableMediaGridSliver] 一致：
/// - 每个 section = 一个标题（固定高度）+ 网格若干行
/// - 网格行高由 [viewportWidth]、[crossAxisCount]、[childAspectRatio] 推算
const double _kHeaderHeight = 48.0;
const double _kHorizontalPadding = 4.0; // 2 * 2 from SliverPadding
const double _kDefaultCrossAxisSpacing = 2.0;
const double _kDefaultMainAxisSpacing = 2.0;

/// 根据时间线分组和视口参数，生成 Scrubber 使用的段落列表（估算偏移）。
List<ScrubberLayoutSegment> buildScrubberSegmentsFromSections({
  required List<TimelineSection> sections,
  required double viewportWidth,
  required int crossAxisCount,
  double headerHeight = _kHeaderHeight,
  double crossAxisSpacing = _kDefaultCrossAxisSpacing,
  double mainAxisSpacing = _kDefaultMainAxisSpacing,
  double childAspectRatio = 1.0,
}) {
  if (sections.isEmpty) return [];

  final contentWidth = viewportWidth - _kHorizontalPadding - (crossAxisCount + 1) * crossAxisSpacing;
  final cellWidth = contentWidth / crossAxisCount;
  final cellHeight = cellWidth / childAspectRatio;
  final rowHeight = cellHeight + mainAxisSpacing;

  double offset = 0.0;
  final result = <ScrubberLayoutSegment>[];

  for (final section in sections) {
    final startOffset = offset;
    final rowCount = (section.assets.length / crossAxisCount).ceil();
    final gridHeight = rowCount > 0 ? rowCount * rowHeight : 0.0;
    offset += headerHeight + gridHeight;
    result.add(ScrubberLayoutSegment(
      startOffset: startOffset,
      endOffset: offset,
      date: section.dateTime,
    ));
  }

  return result;
}
