// lib/presentation/widgets/timeline/scrubber.dart
// 时间线滚动条（Scrubber），参考 immich mobile 实现。
// 显示月份标签，支持拖拽拇指快速定位，并可吸附到月份。

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:prismbox/presentation/widgets/timeline/scrubber_segment.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_scrubber_constants.dart';

/// 简单防抖：在 [interval] 内多次调用 [run] 只执行最后一次 [callback]。
class _Debouncer {
  _Debouncer({required this.interval});
  final Duration interval;
  Timer? _timer;

  void run(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(interval, callback);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// 时间线 Scrubber：右侧可拖拽的滚动条，带月份标签与吸附。
class TimelineScrubber extends StatefulWidget {
  /// 要滚动的 CustomScrollView
  final CustomScrollView child;

  /// 布局段落（由 [buildScrubberSegmentsFromSections] 等生成）
  final List<ScrubberLayoutSegment> layoutSegments;

  /// Scrubber 可视区域高度（通常为屏幕高度）
  final double timelineHeight;

  /// 顶部预留（AppBar、状态栏等）
  final double topPadding;

  /// 底部预留（安全区、底部栏等）
  final double bottomPadding;

  /// 吸附到月份时额外偏移（如顶部 widget 高度）
  final double? monthSegmentSnappingOffset;

  /// 是否吸附到月份
  final bool snapToMonth;

  /// 是否有 AppBar（影响拖拽坐标计算）
  final bool hasAppBar;

  /// 日期显示语言，与时间线一致。为 null 时使用中文（zh_CN）
  final Locale? locale;

  const TimelineScrubber({
    super.key,
    required this.layoutSegments,
    required this.timelineHeight,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.monthSegmentSnappingOffset,
    this.snapToMonth = true,
    this.hasAppBar = true,
    this.locale,
    required this.child,
  });

  @override
  State<TimelineScrubber> createState() => _TimelineScrubberState();
}

class _ScrubberUiSegment {
  final DateTime date;
  final double startOffset;
  final String scrollLabel;
  final bool showSegment;
  /// 对应 layoutSegments 的下标，用于按分组粒度正确吸附
  final int segmentIndex;

  _ScrubberUiSegment({
    required this.date,
    required this.startOffset,
    required this.scrollLabel,
    this.showSegment = false,
    required this.segmentIndex,
  });
}

List<_ScrubberUiSegment> _buildUiSegments({
  required List<ScrubberLayoutSegment> layoutSegments,
  required double scrubberHeight,
  String? localeString,
}) {
  const double offsetThreshold = 40.0;
  final segments = <_ScrubberUiSegment>[];
  if (layoutSegments.isEmpty) return segments;

  final totalExtent = layoutSegments.last.endOffset;
  if (totalExtent <= 0) return segments;

  // 与时间线一致使用中文（zh_CN），或跟随 app locale
  final formatter = DateFormat.yMMM(localeString ?? 'zh_CN');
  DateTime? lastDate;
  double lastOffset = -offsetThreshold;

  for (var i = 0; i < layoutSegments.length; i++) {
    final seg = layoutSegments[i];
    final scrollPercentage = seg.startOffset / totalExtent;
    final startOffset = scrollPercentage * scrubberHeight;
    final label = formatter.format(seg.date);
    final showSegment = lastOffset + offsetThreshold <= startOffset &&
        (lastDate == null || seg.date.year != lastDate.year);

    segments.add(_ScrubberUiSegment(
      date: seg.date,
      startOffset: startOffset,
      scrollLabel: label,
      showSegment: showSegment,
      segmentIndex: i,
    ));
    lastDate = seg.date;
    if (showSegment) lastOffset = startOffset;
  }
  return segments;
}

class _TimelineScrubberState extends State<TimelineScrubber>
    with TickerProviderStateMixin {
  double _thumbTopOffset = 0.0;
  bool _isDragging = false;
  List<_ScrubberUiSegment> _segments = [];
  DateTime? _currentScrubberDate;
  _Debouncer? _scrubberDebouncer;
  String? _lastLabel;

  late AnimationController _thumbAnimationController;
  Timer? _fadeOutTimer;
  late Animation<double> _thumbAnimation;
  late AnimationController _labelAnimationController;
  late Animation<double> _labelAnimation;

  late ScrollController _scrollController;

  double get _scrubberHeight =>
      widget.timelineHeight - widget.topPadding - widget.bottomPadding;

  double get _currentOffset {
    if (!_scrollController.hasClients) return 0.0;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return 0.0;
    return _scrollController.offset * _scrubberHeight / pos.maxScrollExtent;
  }

  @override
  void initState() {
    super.initState();
    _thumbAnimationController = AnimationController(
      vsync: this,
      duration: kTimelineScrubberFadeInDuration,
    );
    _thumbAnimation = CurvedAnimation(
      parent: _thumbAnimationController,
      curve: Curves.fastEaseInToSlowEaseOut,
    );
    _labelAnimationController = AnimationController(
      vsync: this,
      duration: kTimelineScrubberFadeInDuration,
    );
    _labelAnimation = CurvedAnimation(
      parent: _labelAnimationController,
      curve: Curves.fastOutSlowIn,
    );
  }

  String? get _localeString => widget.locale?.toString();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollController = PrimaryScrollController.of(context);
    _segments = _buildUiSegments(
      layoutSegments: widget.layoutSegments,
      scrubberHeight: _scrubberHeight,
      localeString: _localeString,
    );
  }

  @override
  void didUpdateWidget(covariant TimelineScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layoutSegments.lastOrNull?.endOffset !=
            widget.layoutSegments.lastOrNull?.endOffset ||
        oldWidget.locale != widget.locale) {
      _segments = _buildUiSegments(
        layoutSegments: widget.layoutSegments,
        scrubberHeight: _scrubberHeight,
        localeString: _localeString,
      );
    }
  }

  @override
  void dispose() {
    _thumbAnimationController.dispose();
    _labelAnimationController.dispose();
    _fadeOutTimer?.cancel();
    _scrubberDebouncer?.dispose();
    super.dispose();
  }

  void _resetThumbTimer() {
    _fadeOutTimer?.cancel();
    _fadeOutTimer = Timer(kTimelineScrubberFadeOutDuration, () {
      if (mounted) _thumbAnimationController.reverse();
      _fadeOutTimer = null;
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (_isDragging) return false;
    setState(() {
      if (notification is ScrollUpdateNotification) {
        _thumbTopOffset = _currentOffset;
        if (_labelAnimation.status != AnimationStatus.reverse) {
          _labelAnimationController.reverse();
        }
        if (_thumbAnimationController.status != AnimationStatus.forward) {
          _thumbAnimationController.forward();
        }
      }
      _resetThumbTimer();
    });
    return false;
  }

  void _onScrubberDateChanged(DateTime date) {
    if (_currentScrubberDate == date) return;
    _currentScrubberDate = date;
    _scrubberDebouncer ??= _Debouncer(interval: const Duration(milliseconds: 50));
    _scrubberDebouncer!.run(() {
      if (_currentScrubberDate == date) _currentScrubberDate = null;
    });
  }

  void _onDragStart(DragStartDetails _) {
    setState(() {
      _isDragging = true;
      _labelAnimationController.forward();
      _fadeOutTimer?.cancel();
      _lastLabel = null;
    });
  }

  double _calculateDragPosition(DragUpdateDetails details) {
    if (widget.hasAppBar) {
      final dragAreaTop = widget.topPadding;
      final dragAreaBottom = widget.timelineHeight - widget.bottomPadding;
      final dragAreaHeight = dragAreaBottom - dragAreaTop;
      final relativePosition = details.globalPosition.dy - dragAreaTop;
      return relativePosition.clamp(0.0, dragAreaHeight);
    }
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPosition = renderBox.globalToLocal(details.globalPosition);
      return localPosition.dy.clamp(0.0, _scrubberHeight);
    }
    final relativePosition = details.globalPosition.dy - widget.topPadding;
    return relativePosition.clamp(0.0, _scrubberHeight);
  }

  _ScrubberUiSegment? _findNearestMonthSegment(double position) {
    _ScrubberUiSegment? nearest;
    double minDistance = double.infinity;
    for (final segment in _segments) {
      final distance = (segment.startOffset - position).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearest = segment;
      }
    }
    return nearest;
  }

  int _findLayoutSegmentIndex(_ScrubberUiSegment segment) {
    return segment.segmentIndex;
  }

  void _scrollToLayoutSegment(int layoutSegmentIndex) {
    final layoutSegment = widget.layoutSegments[layoutSegmentIndex];
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetScrollOffset = layoutSegment.startOffset;
    final centeredOffset = targetScrollOffset -
        (viewportHeight / 4) +
        100 +
        (widget.monthSegmentSnappingOffset ?? 0.0);
    _scrollController.jumpTo(centeredOffset.clamp(0.0, maxScrollExtent));
  }

  void _snapToSegment(_ScrubberUiSegment segment) {
    setState(() {
      _thumbTopOffset = segment.startOffset;
      final layoutSegmentIndex = _findLayoutSegmentIndex(segment);
      if (layoutSegmentIndex >= 0) _scrollToLayoutSegment(layoutSegmentIndex);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    if (_thumbAnimationController.status != AnimationStatus.forward) {
      _thumbAnimationController.forward();
    }
    final dragPosition = _calculateDragPosition(details);
    final nearestMonthSegment = _findNearestMonthSegment(dragPosition);

    if (nearestMonthSegment != null) {
      final label = nearestMonthSegment.scrollLabel;
      if (_lastLabel != label) {
        HapticFeedback.selectionClick();
        _lastLabel = label;
        _onScrubberDateChanged(nearestMonthSegment.date);
      }
    }

    // 按当前分组粒度吸附：有段落且开启吸附时吸附到最近段落，否则按比例滚动
    if (!widget.snapToMonth || nearestMonthSegment == null) {
      setState(() {
        _thumbTopOffset = dragPosition;
        if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
          _scrollController.jumpTo((dragPosition / _scrubberHeight) *
              _scrollController.position.maxScrollExtent);
        }
      });
    } else {
      _snapToSegment(nearestMonthSegment);
    }
  }

  void _onDragEnd(DragEndDetails _) {
    _labelAnimationController.reverse();
    setState(() => _isDragging = false);
    _currentScrubberDate = null;
    _scrubberDebouncer?.dispose();
    _scrubberDebouncer = null;
    _resetThumbTimer();
  }

  @override
  Widget build(BuildContext context) {
    Text? label;
    if (_scrollController.hasClients) {
      final scrollOffset = _currentOffset;
      final labelText =
          _segments.lastWhereOrNull((s) => s.startOffset <= scrollOffset)?.scrollLabel ??
              _segments.firstOrNull?.scrollLabel;
      label = labelText != null
          ? Text(
              labelText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            )
          : null;
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Stack(
        children: [
          RepaintBoundary(child: widget.child),
          RepaintBoundary(
            child: _SegmentsLayer(
              key: ValueKey('segments_${_isDragging}_${_segments.length}'),
              segments: _segments,
              topPadding: widget.topPadding,
              isDragging: _isDragging,
            ),
          ),
          if (_scrollController.hasClients &&
              _scrollController.position.maxScrollExtent > 0)
            PositionedDirectional(
              top: _thumbTopOffset + widget.topPadding,
              end: 0,
              child: RepaintBoundary(
                child: GestureDetector(
                  onVerticalDragStart: _onDragStart,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  child: _ScrubberThumb(
                    thumbAnimation: _thumbAnimation,
                    labelAnimation: _labelAnimation,
                    label: label,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentsLayer extends StatelessWidget {
  const _SegmentsLayer({
    super.key,
    required this.segments,
    required this.topPadding,
    required this.isDragging,
  });

  final List<_ScrubberUiSegment> segments;
  final double topPadding;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isDragging,
      child: Stack(
        children: segments
            .where((s) => s.showSegment)
            .map(
              (segment) => PositionedDirectional(
                key: ValueKey('segment_${segment.date.millisecondsSinceEpoch}'),
                top: topPadding + segment.startOffset,
                end: 100,
                child: RepaintBoundary(child: _SegmentChip(segment: segment)),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({required this.segment});

  final _ScrubberUiSegment segment;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.only(right: 36.0),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(16.0)),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 28),
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            alignment: Alignment.center,
            child: Text(
              segment.date.year.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollLabel extends StatelessWidget {
  const _ScrollLabel({
    required this.label,
    required this.backgroundColor,
    required this.animation,
  });

  final Text label;
  final Color backgroundColor;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: animation,
        child: Container(
          margin: const EdgeInsets.only(right: 12.0),
          child: Material(
            elevation: 4.0,
            color: backgroundColor,
            borderRadius: const BorderRadius.all(Radius.circular(16.0)),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 28),
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              alignment: Alignment.center,
              child: label,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrubberThumb extends StatelessWidget {
  const _ScrubberThumb({
    required this.thumbAnimation,
    required this.labelAnimation,
    this.label,
  });

  final Animation<double> thumbAnimation;
  final Animation<double> labelAnimation;
  final Text? label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Color.lerp(colorScheme.primary, Colors.black, 0.3) ?? colorScheme.primary
        : colorScheme.primary;

    return AnimatedBuilder(
      animation: thumbAnimation,
      builder: (context, child) =>
          thumbAnimation.value == 0.0 ? const SizedBox() : child!,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).animate(thumbAnimation),
        child: FadeTransition(
          opacity: thumbAnimation,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (label != null)
                _ScrollLabel(
                  label: label!,
                  backgroundColor: backgroundColor,
                  animation: labelAnimation,
                ),
              _CircularThumb(backgroundColor: backgroundColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularThumb extends StatelessWidget {
  const _CircularThumb({required this.backgroundColor});

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const _ArrowPainter(Colors.white),
      child: Material(
        elevation: 4.0,
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(48.0),
          bottomLeft: Radius.circular(48.0),
          topRight: Radius.circular(4.0),
          bottomRight: Radius.circular(4.0),
        ),
        child: Container(
          constraints: BoxConstraints.tight(const Size(48.0 * 0.6, 48.0)),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.color);

  final Color color;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const width = 12.0;
    const height = 8.0;
    final baseX = size.width / 2;
    final baseY = size.height / 2;
    canvas.drawPath(
      _trianglePath(Offset(baseX, baseY - 2.0), width, height, true),
      paint,
    );
    canvas.drawPath(
      _trianglePath(Offset(baseX, baseY + 2.0), width, height, false),
      paint,
    );
  }

  static Path _trianglePath(Offset o, double w, double h, bool isUp) {
    return Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo(o.dx + w, o.dy)
      ..lineTo(o.dx + (w / 2), isUp ? o.dy - h : o.dy + h)
      ..close();
  }
}
