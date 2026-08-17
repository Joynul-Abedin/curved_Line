import 'package:flutter/widgets.dart';

import 'roadmap_geometry.dart';

/// How a [CurvedRoadmap] sizes itself within its parent.
@immutable
class RoadmapSizing {
  /// The road fills the constraints its parent gives it (the default).
  ///
  /// Requires bounded constraints on the winding axis — inside a scroll view
  /// along that axis, use [RoadmapSizing.fixedSegmentExtent] instead. Set
  /// [crossExtent] when the cross axis is also unbounded.
  const RoadmapSizing.fitViewport({this.crossExtent})
      : segmentExtent = null,
        assert(
          crossExtent == null || crossExtent > 0,
          'crossExtent must be positive',
        );

  /// The road's winding-axis length is `segmentCount * segmentExtent`
  /// pixels, independent of incoming constraints — for roads longer than one
  /// screen inside a `SingleChildScrollView`.
  ///
  /// The segment count comes from [RoadmapGeometry.segmentCount], so a shape
  /// that defines its own segments (such as `WaypointCurveStyle`) is sized by
  /// those rather than by `curveCount`.
  const RoadmapSizing.fixedSegmentExtent(
    double this.segmentExtent, {
    this.crossExtent,
  })  : assert(segmentExtent > 0, 'segmentExtent must be positive'),
        assert(
          crossExtent == null || crossExtent > 0,
          'crossExtent must be positive',
        );

  /// Pixels per road segment, or null when filling the viewport.
  final double? segmentExtent;

  /// Forces the road's cross-axis extent in pixels. Required when the parent
  /// gives unbounded constraints on that axis.
  final double? crossExtent;

  /// Resolves the widget's size for [constraints] under [geometry].
  Size resolve(BoxConstraints constraints, RoadmapGeometry geometry) {
    final bool vertical = geometry.orientation == RoadmapOrientation.vertical;

    final double cross = crossExtent ??
        (vertical ? constraints.maxWidth : constraints.maxHeight);
    assert(
      cross.isFinite,
      'CurvedRoadmap got unbounded constraints on its cross axis. Pass '
      'RoadmapSizing(...crossExtent: ...), or give the widget a bounded '
      'width (vertical) / height (horizontal).',
    );

    final double along = segmentExtent != null
        ? geometry.segmentCount * segmentExtent!
        : (vertical ? constraints.maxHeight : constraints.maxWidth);
    assert(
      along.isFinite,
      'CurvedRoadmap got unbounded constraints on its winding axis. Use '
      'RoadmapSizing.fixedSegmentExtent(...) when placing it inside a '
      'scroll view along that axis.',
    );

    // In release builds, degrade to zero rather than laying out at Infinity.
    final double safeCross = cross.isFinite ? cross : 0;
    final double safeAlong = along.isFinite ? along : 0;
    return vertical ? Size(safeCross, safeAlong) : Size(safeAlong, safeCross);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoadmapSizing &&
          other.segmentExtent == segmentExtent &&
          other.crossExtent == crossExtent);

  @override
  int get hashCode => Object.hash(segmentExtent, crossExtent);
}
