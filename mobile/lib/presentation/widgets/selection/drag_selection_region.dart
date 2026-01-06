// lib/presentation/widgets/selection/drag_selection_region.dart

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 滚动方向
enum ScrollDirection {
  forward,
  reverse,
}

/// 资产索引
class AssetIndex {
  final int assetIndex;
  final int sectionIndex;

  const AssetIndex({
    required this.assetIndex,
    required this.sectionIndex,
  });

  @override
  bool operator ==(covariant AssetIndex other) {
    if (identical(this, other)) return true;
    return other.assetIndex == assetIndex && other.sectionIndex == sectionIndex;
  }

  @override
  int get hashCode => assetIndex.hashCode ^ sectionIndex.hashCode;
}

/// 拖动选择区域
class DragSelectionRegion extends StatefulWidget {
  final Widget child;
  final void Function(AssetIndex index)? onStart;
  final void Function(AssetIndex index)? onAssetEnter;
  final void Function()? onEnd;
  final void Function()? onScrollStart;
  final void Function(ScrollDirection direction)? onScroll;

  const DragSelectionRegion({
    super.key,
    required this.child,
    this.onStart,
    this.onAssetEnter,
    this.onEnd,
    this.onScrollStart,
    this.onScroll,
  });

  @override
  State<DragSelectionRegion> createState() => _DragSelectionRegionState();
}

class _DragSelectionRegionState extends State<DragSelectionRegion> {
  AssetIndex? _assetUnderPointer;
  AssetIndex? _anchorAsset;

  // 滚动相关状态
  static const double scrollOffset = 0.10;
  double? _topScrollOffset;
  double? _bottomScrollOffset;
  Timer? _scrollTimer;
  bool _scrollNotified = false;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        _CustomLongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            _CustomLongPressGestureRecognizer>(
          () => _CustomLongPressGestureRecognizer(),
          _registerCallbacks,
        ),
      },
      child: widget.child,
    );
  }

  void _registerCallbacks(_CustomLongPressGestureRecognizer recognizer) {
    recognizer.onLongPressMoveUpdate = (details) => _onLongPressMove(details);
    recognizer.onLongPressStart = (details) => _onLongPressStart(details);
    recognizer.onLongPressUp = _onLongPressEnd;
  }

  AssetIndex? _getAssetIndexAtPosition(Offset position) {
    final box = context.findAncestorRenderObjectOfType<RenderBox>();
    if (box == null) return null;

    final hitTestResult = BoxHitTestResult();
    final local = box.globalToLocal(position);
    if (!box.hitTest(hitTestResult, position: local)) return null;

    return (hitTestResult.path.firstWhereOrNull(
            (hit) => hit.target is _AssetIndexProxy)?.target as _AssetIndexProxy?)
        ?.index;
  }

  void _onLongPressStart(LongPressStartDetails event) {
    final height = context.size?.height;
    if (height != null && (_topScrollOffset == null || _bottomScrollOffset == null)) {
      _topScrollOffset = height * scrollOffset;
      _bottomScrollOffset = height - _topScrollOffset!;
    }

    final initialHit = _getAssetIndexAtPosition(event.globalPosition);
    _anchorAsset = initialHit;
    if (initialHit == null) return;

    if (_anchorAsset != null) {
      widget.onStart?.call(_anchorAsset!);
    }
  }

  void _onLongPressEnd() {
    _scrollNotified = false;
    _scrollTimer?.cancel();
    widget.onEnd?.call();
  }

  void _onLongPressMove(LongPressMoveUpdateDetails event) {
    if (_anchorAsset == null) return;
    if (_topScrollOffset == null || _bottomScrollOffset == null) return;

    final currentDy = event.localPosition.dy;

    if (currentDy > _bottomScrollOffset!) {
      _scrollTimer ??= Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => widget.onScroll?.call(ScrollDirection.forward),
      );
    } else if (currentDy < _topScrollOffset!) {
      _scrollTimer ??= Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => widget.onScroll?.call(ScrollDirection.reverse),
      );
    } else {
      _scrollTimer?.cancel();
      _scrollTimer = null;
    }

    final currentlyTouchingAsset = _getAssetIndexAtPosition(event.globalPosition);
    if (currentlyTouchingAsset == null) return;

    if (_assetUnderPointer != currentlyTouchingAsset) {
      if (!_scrollNotified) {
        _scrollNotified = true;
        widget.onScrollStart?.call();
      }

      widget.onAssetEnter?.call(currentlyTouchingAsset);
      _assetUnderPointer = currentlyTouchingAsset;
    }
  }
}

class _CustomLongPressGestureRecognizer extends LongPressGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

/// 资产索引包装器
class AssetIndexWrapper extends SingleChildRenderObjectWidget {
  final int assetIndex;
  final int sectionIndex;

  const AssetIndexWrapper({
    required Widget super.child,
    required this.assetIndex,
    required this.sectionIndex,
    super.key,
  });

  @override
  _AssetIndexProxy createRenderObject(BuildContext context) {
    return _AssetIndexProxy(
      index: AssetIndex(
        assetIndex: assetIndex,
        sectionIndex: sectionIndex,
      ),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _AssetIndexProxy renderObject,
  ) {
    renderObject.index = AssetIndex(
      assetIndex: assetIndex,
      sectionIndex: sectionIndex,
    );
  }
}

class _AssetIndexProxy extends RenderProxyBox {
  AssetIndex index;

  _AssetIndexProxy({required this.index});
}

